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
import de.polygonal.ds.ArrayUtil;
import de.polygonal.ds.IntHashTable;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.effect.SpriteSheetEffect;
import de.polygonal.zz.render.effect.TextureEffect;
import de.polygonal.zz.render.module.RenderModuleConfig;
import de.polygonal.zz.render.RenderSurface;
import de.polygonal.zz.render.texture.Image;
import de.polygonal.zz.render.texture.Rect;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.scene.AlphaState;
import de.polygonal.zz.scene.Geometry;
import de.polygonal.zz.scene.GeometryType;
import de.polygonal.zz.scene.Renderer;
import de.polygonal.zz.scene.Spatial;
import nme.display.Graphics;
import nme.display.Tilesheet;
import nme.geom.Rectangle;

//private typedef E = de.polygonal.zz.render.effect.Effect;

class TileRenderer extends Renderer
{
	public var numCallsToDrawTiles:Int;
	
	var _canvas:Graphics;
	var _buffer:Array<Float>;
	var _bufferSize:Int;
	var _tilesheetLUT:IntHashTable<Tilesheet>;
	
	var _batchSize:Int;
	
	var _currTilesheetFlags:Int;
	var _currTilesheet:Tilesheet;
	var _smooth:Bool;
	
	public function new(config:TileRendererConfig)
	{
		super(config);
		
		_canvas = RenderSurface.root.graphics;
		_tilesheetLUT = new IntHashTable(64, 64, false, 64);
		
		//max. 11 valus/tile: x, y, id, a, b, c, d, red, green, blue, alpha
		_buffer = ArrayUtil.alloc(maxBatchSize * 11);
		_bufferSize = 0;
		
		//batch rendering is on by default
		drawDeferred = drawDeferredBatch;
	}
	
	override public function drawTextureEffect(effect:TextureEffect):Void
	{
		super.drawTextureEffect(effect);
		
		currTexture = effect.tex;
		
		_currTilesheetFlags = push(effect.crop, 0, currGeometry, effect);
		_currTilesheet = getTilesheet(effect);
		
		_smooth = effect.smooth;
		flush();
	}
	
	override public function drawSpriteSheetEffect(effect:SpriteSheetEffect):Void
	{
		super.drawSpriteSheetEffect(effect);
		
		var frame = effect.frame;
		
		_currTilesheetFlags = push(effect.sheet.getCropRectAt(frame), frame, currGeometry, effect);
		_currTilesheet = getTilesheet(effect);
		
		_smooth = effect.smooth;
		flush();
	}
	
	override public function drawDeferredBatch():Void
	{
		//nothing to draw?
		if (_deferredObjectsList.__next == null) return;
		
		//temporarily disable deferred drawing
		var save = drawDeferred;
		drawDeferred = null;
		
		//var numBatchCalls = 0;
		var currEffectFlags = -1;
		var currStateFlags = -1;
		//var states:DA<GlobalState> = null;
		
		currTexture = null;
		
		var frame:Int;
		var crop:Rect;
		
		var o = _deferredObjectsList.__next;
		while (o != null)
		{
			if (o.isNode())
			{
				//when deferred drawing is active, a call to drawNode() simply adds the node to the list of deferred objects;
				//since deferred drawing is temporarly disabled, drawNode(o) will draw the effect attached to the node.
				_deferredObjectsNode = o;
				drawNode(o.__node);
				o = o.__next;
				continue;
			}
			
			var g = o.__geometry;
			
			//nothing to draw; skip
			if (o.effect == null)
			{
				o = o.__next;
				continue;
			}
			
			var effect:Effect = o.effect;
			
			var effectFlags = effect.flags;
			if (currEffectFlags < 0)
			{
				//insert first first geometry node into batch
				currEffectFlags = effectFlags;
				currTexture = effect.tex;
				currStateFlags = g.stateFlags;
				//states = g.states;
				//if (allowGlobalState)
					//setGlobalState(states);
					
				_smooth = effect.smooth;
				
				//draw batched
				frame =
				if (effect.__spriteSheetEffect != null)
					effect.__spriteSheetEffect.frame;
				else
					0;
				crop = effect.__textureEffect.crop;
				
				_currTilesheetFlags = push(crop, frame, g, effect);
				_currTilesheet = getTilesheet(effect);
				
				o = o.__next;
				continue;
			}
			
			//render state changed?
			var effectsChanged = effectFlags != currEffectFlags;
			var textureChanged = effect.tex != currTexture;
			var stateChanged   = g.stateFlags != currStateFlags;
			var batchExhausted = _batchSize == 100;
			var batchExhausted = false;
			
			if (effectsChanged || textureChanged || stateChanged || batchExhausted)
			{
				//current batch needs to be drawn
				
				#if verbose
				//trace('flags');
				//trace(NumberFormat.toBin(currEffectFlags, '.', true));
				//trace(NumberFormat.toBin(effectFlags, '.', true));
				
				
				var reason =
				if (effectsChanged) 'effects';
				else if (textureChanged) 'texture';
				else if (stateChanged) 'state';
				else if (batchExhausted) 'exhausted';
				L.d('state changed, reason: $reason, current batch size: $_batchSize', 'tile');
				#end
				
				flush();
				
				//initialize new batch for current geometry
				currEffectFlags = effectFlags;
				currTexture = effect.tex;
				currStateFlags = g.stateFlags;
				
				_smooth = effect.smooth;
				
				//states = g.states;
				
				//if (stateChanged && allowGlobalState)
					//setGlobalState(states);
			}
			
			//draw batched
			frame =
			if (effect.__spriteSheetEffect != null)
				effect.__spriteSheetEffect.frame;
			else
				0;
			crop = effect.__textureEffect.crop;
			
			_currTilesheetFlags = push(crop, frame, g, effect);
			_currTilesheet = getTilesheet(effect);
			
			o = o.__next;
		}
		
		//draw remainder
		if (_batchSize > 0)
		{
			//if (allowGlobalState)
				//setGlobalState(states);
			
			flush();
			
			//currBrush.draw(this);
			//numBatchCalls++;
		}
		
		currTexture = null;
		
		//restore deferred drawing
		drawDeferred = save;
	}
	
	override function drawElements():Void
	{
		trace('draw elements');
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
				e &= ~E.E.EFFECT_TEXTURE;*/
			
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
	
	override function onBeginScene():Void
	{
		_canvas.clear();
		numCallsToDrawTiles = 0;
	}
	
	override public function freeTex(image:Image):Void
	{
		var tex = _textureLookup.get(image.key);
		
		var tilesheet = _tilesheetLUT.get(tex.key);
		_tilesheetLUT.clr(tex.key);
		
		tilesheet.nmeBitmap = null;
		tilesheet.nmeHandle = null;
		
		var imageId = image.id;
		L.d('dispose Tilesheet (image id: $imageId)', 'tile');
		
		super.freeTex(image);
	}
	
	override public function createTex(image:Image):Tex
	{
		return new Tex(image, false, false);
	}
	
	function drawTriangle(a:Vec3, b:Vec3, c:Vec3, color:Int):Void
	{
		throw 1;
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
		throw 1;
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
	
	function push(rect:Rect, frame:Int, g:Geometry, effect:Effect):Int
	{
		var flags = Tilesheet.TILE_TRANS_2x2;
		var xform = g.world;
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
		
		if (effect.flags & Effect.EFFECT_COLOR_XFORM > 0)
		{
			flags |= Tilesheet.TILE_RGB;
			var mult = effect.colorXForm.multiplier;
			add(mult.x);
			add(mult.y);
			add(mult.z);
		}
		
		if (effect.flags & Effect.EFFECT_ALPHA > 0)
		{
			flags |= Tilesheet.TILE_ALPHA;
			add(effect.alpha);
		}
		
		_batchSize++;
		
		return flags;
	}
	
	function flush():Void
	{
		#if verbose
		L.d('drawing #$_batchSize effect(s) (smooth: $_smooth)', 'tile');
		#end
		
		var src = _buffer;
		var dst = new Array<Float>();
		dst[_bufferSize - 1] = cast null;
		
		for (i in 0..._bufferSize) untyped dst.__unsafe_set(i, src.__unsafe_get(i));
		
		_canvas.drawTiles(_currTilesheet, dst, _smooth, _currTilesheetFlags);
		dst = null;
		
		_bufferSize = 0;
		_batchSize = 0;
		numCallsToDrawTiles++;
	}
	
	inline function getTilesheet(effect:Effect):Tilesheet
	{
		var tilesheet = _tilesheetLUT.get(effect.tex.key);
		if (tilesheet == null) tilesheet = createTilesheet(effect);
		return tilesheet;
	}
	
	function createTilesheet(effect:Effect):Tilesheet
	{
		var tex = effect.tex;
		
		var key = tex.key;
		var imageId = tex.image.id;
		L.d('create Tilesheet (texture key: $key, image id: $imageId', 'tile');
		
		var tilesheet = new Tilesheet(tex.image.data);
		
		_tilesheetLUT.set(key, tilesheet);
		
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
		return tilesheet;
	}
	
	inline function add(x:Float):Void
	{
		untyped _buffer.__unsafe_set(_bufferSize++, x);
	}
	
	override function setAlphaState(state:AlphaState):Void {}
}