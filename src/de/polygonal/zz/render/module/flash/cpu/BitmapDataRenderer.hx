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
 * Copyright (c) 2012 Michael Baczynski, http://www.polygonal.de
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
package de.polygonal.zz.render.module.flash.cpu;

import de.polygonal.core.fmt.NumberFormat;
import de.polygonal.core.math.Mat33;
import de.polygonal.core.math.Mat44;
import de.polygonal.core.math.Vec3;
import de.polygonal.ds.IntHashTable;
import de.polygonal.flash.display.DisplayListUtil;
import de.polygonal.gl.color.RGBA;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.effect.Effect.*;
import de.polygonal.zz.render.effect.SpriteSheetEffect;
import de.polygonal.zz.render.effect.TextureEffect;
import de.polygonal.zz.render.module.RenderModuleConfig;
import de.polygonal.zz.render.texture.Image;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.scene.Renderer;
import de.polygonal.zz.scene.XForm;
import de.polygonal.zz.render.RenderSurface;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.PixelSnapping;
import flash.display.Shape;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import de.polygonal.core.util.Assert;

using de.polygonal.ds.BitFlags;

class BitmapDataRenderer extends Renderer
{
	public var canvas(default, null):Bitmap;
	
	var _bitmap:BitmapData;
	var _scratchMatrix:Matrix;
	var _scratchColorTransform:ColorTransform;
	var _scratchColorTransformAlpha:ColorTransform;
	var _scratchRect:Rectangle;
	var _scratchPoint:Point;
	var _scratchShape:Shape;
	var _scratchXForm:XForm;
	
	var _tileLookup:IntHashTable<Tile>;
	
	public function new(config:RenderModuleConfig)
	{
		super(config);
		
		_bitmap = new BitmapData(this.width, this.height, true, 0);
		canvas = new Bitmap(_bitmap, PixelSnapping.NEVER, false);
		
		_scratchMatrix = new Matrix();
		_scratchColorTransform = new ColorTransform();
		_scratchColorTransformAlpha = new ColorTransform();
		_scratchRect = new Rectangle();
		_scratchPoint = new Point();
		_tileLookup = new IntHashTable(512, 512, false, 512);
		_scratchShape = new Shape();
		_scratchXForm = new XForm();
		
		drawDeferred = null;
		
		var container =
		if (config != null && Reflect.hasField(config, 'container'))
			config.container;
		else
			RenderSurface.root;
		container.addChild(canvas);
	}
	
	override public function free():Void
	{
		super.free();
		
		_bitmap.dispose();
		_bitmap = null;
		
		_scratchMatrix = null;
		_scratchColorTransform = null;
		_scratchColorTransformAlpha = null;
		_scratchRect = null;
		_scratchPoint = null;
		_scratchShape = null;
		
		_tileLookup.free();
		_tileLookup = null;
		
		DisplayListUtil.remove(canvas);
		canvas = null;
	}
	
	public function getBitmap():Bitmap
	{
		return canvas;
	}
	
	override public function createTex(image:Image):Tex
	{
		return new Tex(image, false, false);
	}
	
	override public function drawEffect(effect:Effect):Void
	{
		//SRT transform
		var world = currGeometry.world;
		var s = world.getScale();
		var r = world.getRotate();
		var t = world.getTranslate();
		
		if (currGeometry.rotation == 0)
		{
			var color =
			if (effect.alpha == 1)
				(0xff << 24) | effect.color;
			else
				(cast(effect.alpha * 0xff) << 24) | effect.color;
			
			if (effect.flags & EFFECT_COLOR_XFORM > 0)
				color = effect.colorXForm.transformRGBA(color);
			
			_scratchRect.x = t.x;
			_scratchRect.y = t.y;
			_scratchRect.width = s.x;
			_scratchRect.height = s.y;
			_bitmap.fillRect(_scratchRect, color);
			return;
		}
		
		var shape = _scratchShape;
		shape.graphics.clear();
		shape.graphics.beginFill(effect.color, effect.alpha);
		shape.graphics.drawRect(0, 0, s.x, s.y);
		
		var flashMatrix = transformationToMatrix(world, s.x, s.y, _scratchMatrix);
		var flashColorTransform = getColorTransform(effect);
		
		var smooth = false;//effect.smooth;
		_bitmap.draw(_scratchShape, flashMatrix, flashColorTransform, null, null, smooth);
	}
	
	override public function drawTextureEffect(effect:TextureEffect):Void
	{
		//create bitmap tile for repeated use..
		//create/retrurn  MovieClip  for geometry
		
		//var mc <- currGeometry.key
		
		var tex = effect.tex;
		
		var uv = effect.crop;
		
		var key = tex.key;
		var tile = _tileLookup.get(key);
		if (tile == null)
		{
			//create bitmap tile and cache it for repeated use
			_scratchRect.x = uv.x;
			_scratchRect.y = uv.y;
			_scratchRect.width = uv.w;
			_scratchRect.height = uv.h;
			_scratchPoint.x = 0;
			_scratchPoint.y = 0;
			
			var bmd = new BitmapData(cast uv.w, cast uv.h, true, 0);
			bmd.copyPixels(tex.image.data, _scratchRect, _scratchPoint);
			
			tile = new Tile();
			tile.b = bmd;
			tile.r = bmd.rect.clone();
			
			_tileLookup.set(key, tile);
		}
		
		var world = currGeometry.world;
		var s = world.getScale();
		var r = world.getRotate();
		var t = world.getTranslate();
		
		//fast blitting if no rotation, scale and special effects
		if (currGeometry.rotation == 0)
		{
			if (s.x == uv.w && s.y == uv.h)
			{
				if (effect.flags == EFFECT_TEXTURE)
				{
					_scratchPoint.x = t.x;
					_scratchPoint.y = t.y;
					_bitmap.copyPixels(tile.b, tile.r, _scratchPoint, null, null, true);
					return;
				}
			}
		}
		
		var flashMatrix = transformationToMatrix(world, uv.w, uv.h, _scratchMatrix);
		var flashColorTransform = getColorTransform(effect);
		
		var smooth = false;//effect.smooth;
		_bitmap.draw(tile.b, flashMatrix, flashColorTransform, null, null, smooth);
	}
	
	override public function drawSpriteSheetEffect(effect:SpriteSheetEffect):Void
	{
		var tex = effect.tex;
		var uv = effect.crop;
		
		var key = effect.frame << 16 | tex.key;
		var tile = _tileLookup.get(key);
		if (tile == null)
		{
			//create bitmap tile and cache it for repeated use
			_scratchRect.x = uv.x;
			_scratchRect.y = uv.y;
			_scratchRect.width = uv.w;
			_scratchRect.height = uv.h;
			_scratchPoint.x = 0;
			_scratchPoint.y = 0;
			
			var bmd = new BitmapData(cast uv.w, cast uv.h, true, 0);
			bmd.copyPixels(tex.image.data, _scratchRect, _scratchPoint);
			
			tile = new Tile();
			tile.b = bmd;
			tile.r = bmd.rect.clone();
			
			_tileLookup.set(key, tile);
		}
		
		var world = currGeometry.world;
		var s = world.getScale();
		var r = world.getRotate();
		var t = world.getTranslate();
		
		//fast blitting if no rotation, scale and effects
		/*if (currGeometry.rotation == 0)
		{
			if (s.x == uv.w && s.y == uv.h)
			{
				if (effect.flags == EFFECT_TEXTURE)
				{
					_scratchPoint.x = t.x;
					_scratchPoint.y = t.y;
					_bitmap.copyPixels(tile.b, tile.r, _scratchPoint, null, null, true);
					return;
				}
			}
		}*/
		
		var flashMatrix = transformationToMatrix(world, uv.w, uv.h, _scratchMatrix);
		var flashColorTransform = getColorTransform(effect);
		_bitmap.draw(tile.b, flashMatrix, flashColorTransform, null, null, false);
	}
	
	override public function onViewPortChange():Void
	{
		_projMatrix.setIdentity();
	}
	
	override function onBeginScene():Void
	{
		_bitmap.lock();
		var r = _backgroundColor.x;
		var g = _backgroundColor.y;
		var b = _backgroundColor.z;
		var a = _backgroundColor.w;
		_bitmap.fillRect(_bitmap.rect, RGBA.ofFloat4(r, g, b, a));
	}
	
	override function onEndScene():Void
	{
		_bitmap.unlock();
	}
	
	inline function transformationToMatrix(xf:XForm, w:Float, h:Float, m:Matrix):Matrix
	{
		//matrix layout
		//|a c tx|
		//|b d ty|
		//|u v w |
		
		#if debug
		D.assert(xf.isRSMatrix(), 'xf.isRSMatrix()');
		#end
		
		var frame = getCamera().local;
		if (!frame.isIdentity())
		{
			_scratchXForm.product(frame, xf);
			_scratchXForm.setf(XForm.BIT_HINT_RS_MATRIX);
			xf = _scratchXForm;
		}
		
		var r = xf.getRotate();
		var s = xf.getScale();
		var sx = (s.x / w);
		m.a = sx * r.m11;
		m.b = sx * r.m21;
		var sy = (s.y / h);
		m.c = sy * r.m12;
		m.d = sy * r.m22;
		var v = xf.getTranslate();
		m.tx = v.x;
		m.ty = v.y;
		
		return m;
	}
	
	inline function getColorTransform(effect:Effect):ColorTransform
	{
		var flags = effect.flags;
		var ct = null;
		if (flags & EFFECT_ALPHA > 0)
		{
			ct = _scratchColorTransformAlpha;
			ct.alphaMultiplier = effect.alpha;
			
			if (flags & EFFECT_COLOR_XFORM > 0)
				ct.concat(convert(effect));
		}
		else
		if (flags & EFFECT_COLOR_XFORM > 0)
			ct = convert(effect);
		return ct;
	}
	
	inline function convert(effect:Effect):ColorTransform
	{
		var ct = _scratchColorTransform;
		
		var m = effect.colorXForm.multiplier;
		ct.redMultiplier   = m.r;
		ct.greenMultiplier = m.g;
		ct.blueMultiplier  = m.b;
		ct.alphaMultiplier = m.a * effect.alpha;
		
		var o = effect.colorXForm.offset;
		ct.redOffset   = o.r;
		ct.greenOffset = o.g;
		ct.blueOffset  = o.b;
		ct.alphaOffset = o.a;
		
		return ct;
	}
}

private class Tile
{
	public var b:BitmapData;
	public var r:Rectangle;
	
	public function new() {}
}