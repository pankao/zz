/*
 *                            _/                                                    _/
 *       _/_/_/      _/_/    _/  _/    _/    _/_/_/    _/_/    _/_/_/      _/_/_/  _/
 *      _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *     _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *    _/_/_/      _/_/    _/    _/_/_/    _/_/_/    _/_/    _/    _/    _/_/_/  _/
 *   _/                            _/        _/
 *  _/                        _/_/      _/_/
 *
 * POLYGONAL - A HAXE LIBRARY FOR GAME DEVELOPERS
 * Copyright (c) 2009 Michael Baczynski, http://www.polygonal.de
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
package de.polygonal.zz.render.module.nme;

import de.polygonal.core.math.Vec3;
import de.polygonal.ds.IntHashTable;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.effect.Effect.*;
import de.polygonal.zz.render.effect.FontEffect;
import de.polygonal.zz.render.effect.SpriteSheetEffect;
import de.polygonal.zz.render.effect.TextureEffect;
import de.polygonal.zz.render.texture.Image;
import de.polygonal.zz.render.texture.Rect;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.scene.AlphaState;
import de.polygonal.zz.scene.GeometryType;
import de.polygonal.zz.scene.Renderer;
import de.polygonal.zz.scene.Spatial;
import de.polygonal.zz.render.RenderSurface;
import flash.geom.Rectangle;
import nme.display.Graphics;
import nme.display.Tilesheet;
import nme.geom.Rectangle;
import de.polygonal.core.util.Assert;

class TileRenderer extends Renderer
{
	//TODO flush if buffer is full
	inline static var MAX_BUFFER_SIZE = 4096;
	
	public var numCallsToDrawTiles:Int;
	
	var _canvas:Graphics;
	var _data:Array<Float>;
	var _tilesheetLUT:IntHashTable<Tilesheet>;
	
	var _batchActive:Bool;
	var _batchSize:Int;
	
	var _currTilesheetFlags:Int;
	var _currTilesheet:Tilesheet;
	
	public function new()
	{
		super();
		
		_canvas = RenderSurface.root.graphics;
		_tilesheetLUT = new IntHashTable(64, 64, false, 64);
		_data = new Array<Float>();
		_batchActive = false;
		
		//batch rendering is on by default
		drawDeferred = drawDeferredBatch;
	}
	
	override public function drawTextureEffect(effect:TextureEffect):Void
	{
		_currTilesheetFlags = draw(effect.__textureEffect.crop, 0, effect);
		_currTilesheet = getTilesheet(effect);
		
		if (!_batchActive) flush();
	}
	
	override public function drawSpriteSheetEffect(effect:SpriteSheetEffect):Void
	{
		var frame = effect.frame;
		_currTilesheetFlags = draw(effect.sheet.getCropRectAt(frame), frame, effect);
		_currTilesheet = getTilesheet(effect);
		
		if (!_batchActive) flush();
	}
	
	override public function drawDeferredBatch():Void
	{
		if (_deferredObjects.isEmpty()) return;
		
		//disable deferred drawing
		var save = drawDeferred;
		drawDeferred = null;
		
		var prevEffectFlags = -1;
		var prevTexture = null;
		
		var i = 0;
		var k = _deferredObjects.size();
		
		while (i < k)
		{
			var o = _deferredObjects.get(i++);
			
			if (o.isNode())
			{
				currNode = o.__node;
				
				if (Std.is(o.effect, FontEffect))
				{
					if (_batchActive)
					{
						flush();
						_batchActive = false;
					}
					_batchActive = true;
					o.effect.draw(this);
					flush();
					_batchActive = false;
				}
				continue;
			}
			
			var e = o.effect;
			
			if (e == null) continue;
			
			currGeometry = o.__geometry;
			
			if (prevEffectFlags == -1)
			{
				//start new batch
				prevEffectFlags = e.flags;
				prevTexture = e.tex;
				
				_batchActive = true;
				
				if (e.__spriteSheetEffect != null)
					drawSpriteSheetEffect(e.__spriteSheetEffect);
				else
					drawTextureEffect(e.__textureEffect);
			}
			else
			{
				//TODO store texture id in flag?
				
				//effect state change or batch exhausted?
				if (e.flags != prevEffectFlags || e.tex != prevTexture) //currBrush.isFull()
				{
					flush();
					
					//start new batch
					prevEffectFlags = e.flags;
					prevTexture = e.tex;
					
					_batchActive = true;
					
					if (e.__spriteSheetEffect != null)
						drawSpriteSheetEffect(e.__spriteSheetEffect);
					else
						drawTextureEffect(e.__textureEffect);
				}
				else
				{
					//keep accumulating
					if (e.__spriteSheetEffect != null)
						drawSpriteSheetEffect(e.__spriteSheetEffect);
					else
						drawTextureEffect(e.__textureEffect);
				}
			}
		}
		
		if (_batchActive)
		{
			flush();
			_batchActive = false;
		}
		
		//restore deferred drawing
		drawDeferred = save;
	}
	
	override function drawElements()
	{
		if (currGeometry.type == GeometryType.QUAD)
		{
			if (currEffect == null)
			{
				return;
			}
			
			var e = currEffect.flags;
			
			var textureFlags = 0;
			
			/*if (allowTextures)
			{
				if (currTexture != null)
				{
					currStage3DTexture = initStage3DTexture(currTexture);
					textureFlags = currStage3DTexture.flags;
				}
			}
			else
				e &= ~EFF_TEXTURE;*/
				
			
			var geometry = currGeometry;
			var mvp = setModelViewProjMatrix(geometry);
			
			var v = new Array<Vec3>();
			var src = geometry.vertices;
			var i = 0;
			var k = src.length;
			while (i < k) v.push(toScreen(geometry, src[i++])); //TODO 2d or 3d
			
			var indices = geometry.indices;
			var i = 0;
			var k = indices.length;
			while (i < k)
			{
				var a = v[indices[i++]];
				var b = v[indices[i++]];
				var c = v[indices[i++]];
				drawTriangle(a, b, c, 0);
			}
		}
	}
	
	override function onBeginScene()
	{
		_data = [];
		_canvas.clear();
		numCallsToDrawTiles = 0;
	}
	
	override public function createTex(image:Image):Tex
	{
		return new Tex(image, false, false);
	}
	
	override function getType():Int
	{
		return Renderer.TYPE_NME_TILES;
	}
	
	function drawTriangle(a:Vec3, b:Vec3, c:Vec3, color:Int)
	{
		var g:flash.display.Graphics = _canvas;
		g.beginFill(currEffect.color, currEffect.alpha);
		g.moveTo(a.x, a.y);
		g.lineTo(b.x, b.y);
		g.lineTo(c.x, c.y);
		g.lineTo(a.x, a.y);
		g.endFill();
	}
	
	function toScreen(spatial:Spatial, x:Vec3):Vec3
	{
		//local space -> world space
		var w = spatial.world.applyForward(x, new Vec3());
		
		//world space -> clip space
		var c = currViewProjMatrix.timesVectorConst(w, new Vec3());
		
		//clip space -> screen space
		var bound = RenderSurface.bound;
		var x = (c.x + 1) * bound.centerX + bound.minX;
		var y = (1 - c.y) * bound.centerY + bound.minY;
		
		return new Vec3(x, y);
	}
	
	function draw(rect:Rect, frame:Int, effect:Effect):Int
	{
		var flags = Tilesheet.TILE_TRANS_2x2;
		var xform = currGeometry.world;
		var t = xform.getTranslate();
		var s = xform.getScale();
		var sx = s.x / rect.w;
		var sy = s.y / rect.h;
		var m = xform.getMatrix();
		
		add(t.x);
		add(t.y);
		add(frame);
		add(m.m11 * sx);
		add(m.m12 * sy);
		add(m.m21 * sx);
		add(m.m22 * sy);
		
		if (effect.flags & EFF_COLOR_XFORM > 0)
		{
			flags |= Tilesheet.TILE_RGB;
			var offset = effect.colorXForm.offset;
			add(offset.r);
			add(offset.g);
			add(offset.b);
		}
		
		if (effect.flags & EFF_ALPHA > 0)
		{
			flags |= Tilesheet.TILE_ALPHA;
			add(effect.alpha);
		}
		
		return flags;
	}
	
	inline function flush()
	{
		var smooth = false;
		_canvas.drawTiles(_currTilesheet, _data, smooth, _currTilesheetFlags);
		_data = [];
		numCallsToDrawTiles++;
	}
	
	inline function getTilesheet(effect:Effect):Tilesheet
	{
		var tex = effect.tex;
		var tilesheet = _tilesheetLUT.get(tex.key);
		if (tilesheet == null)
		{
			tilesheet = new Tilesheet(tex.image.data);
			_tilesheetLUT.set(tex.key, tilesheet);
			
			if (effect.__spriteSheetEffect != null)
			{
				var sheet = effect.__spriteSheetEffect.sheet;
				for (i in 0...sheet.frameCount)
				{
					var rect = sheet.getCropRectAt(i);
					tilesheet.addTileRect(new Rectangle(rect.x, rect.y, rect.w, rect.h));
				}
			}
			else
			if (effect.__textureEffect != null)
			{
				var rect = effect.__textureEffect.crop;
				tilesheet.addTileRect(new Rectangle(rect.x, rect.y, rect.w, rect.h));
			}
		}
		return tilesheet;
	}
	
	inline function add(x:Float)
	{
		_data.push(x);
	}
}