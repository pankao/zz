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
package de.polygonal.zz.render.module.js;

import de.polygonal.gl.color.ColorRGBA;
import de.polygonal.gl.color.RGBA;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.effect.Effect.*;
import de.polygonal.zz.render.effect.SpriteSheetEffect;
import de.polygonal.zz.render.effect.TextureEffect;
import de.polygonal.zz.render.texture.Image;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.scene.Renderer;
import de.polygonal.zz.render.RenderSurface;

import js.w3c.html5.Canvas2DContext;

class CanvasRenderer extends Renderer
{
	public var context:CanvasRenderingContext2D;
	
	public function new()
	{
		super();
		context = RenderSurface.context;
	}
	
	override public function free():Void
	{
		super.free();
	}
	
	override public function createTex(image:Image):Tex
	{
		return new Tex(image, false, false);
	}
	
	override public function drawEffect(effect:Effect):Void
	{
		var world = currGeometry.world;
		var s = world.getScale();
		var r = world.getRotate();
		var t = world.getTranslate();
		
		if (currGeometry.rotation == 0)
		{
			context.fillRect(t.x, t.y, s.x, s.y);
			context.fillStyle = getFillStyle(effect);
		}
		else
		{
			var sx = s.x;
			var sy = s.y;
			var a = sx * r.m11;
			var b = sx * r.m21;
			var c = sy * r.m12;
			var d = sy * r.m22;
			var e = t.x;
			var f = t.y;
			
			context.save();
			context.setTransform(a, b, c, d, e, f);
			context.fillRect(0, 0, 1, 1);
			context.fillStyle = getFillStyle(effect);
			context.restore();
		}
	}
	
	//TODO color transformation
	override public function drawTextureEffect(effect:TextureEffect):Void
	{
		var world = currGeometry.world;
		var s = world.getScale();
		var r = world.getRotate();
		var t = world.getTranslate();
		
		var uv = effect.crop;
		
		if (effect.alpha < 1)
			context.globalAlpha = effect.alpha;
		else
			context.globalAlpha = 1;
		
		if (currGeometry.rotation == 0)
		{
			if (s.x == uv.w && s.y == uv.h)
			{
				//just translation
				context.drawImage(effect.tex.image.data, t.x, t.y);
				return;
			}
		}
		
		var sx = s.x / uv.w;
		var sy = s.y / uv.h;
		var a = sx * r.m11;
		var b = sx * r.m21;
		var c = sy * r.m12;
		var d = sy * r.m22;
		var e = t.x;
		var f = t.y;
		
		context.setTransform(a, b, c, d, e, f);
		context.drawImage(effect.tex.image.data, 0, 0);
	}
	
	//TODO alpha and color transformation
	override public function drawSpriteSheetEffect(effect:SpriteSheetEffect)
	{
		var world = currGeometry.world;
		var s = world.getScale();
		var r = world.getRotate();
		var t = world.getTranslate();
		
		var uv = effect.crop;
		
		if (effect.alpha < 1)
			context.globalAlpha = effect.alpha;
		else
			context.globalAlpha = 1;
		
		if (currGeometry.rotation == 0)
		{
			context.drawImage(effect.tex.image.data,
				uv.x, uv.y, uv.w, uv.h,
				t.x, t.y, s.x, s.y);
		}
		else
		{
			var a = r.m11;
			var b = r.m21;
			var c = r.m12;
			var d = r.m22;
			var e = t.x;
			var f = t.y;
			
			context.setTransform(a, b, c, d, e, f);
			context.drawImage(effect.tex.image.data,
				uv.x, uv.y, uv.w, uv.h, 0, 0, s.x, s.y);
		}
	}
	
	override function onBeginScene()
	{
		context.clearRect(0, 0, RenderSurface.width, RenderSurface.height);
		context.fillRect(0, 0, RenderSurface.width, RenderSurface.height);
		context.fillStyle = toRGBA(ColorRGBA.toInt(_backgroundColor), _backgroundColor.a);
		context.save();
	}
	
	override function onEndScene()
	{
		super.onEndScene();
		context.restore();
	}
	
	override function getType():Int
	{
		return Renderer.TYPE_HTML5_CANVAS;
	}
	
	inline function toRGBA(rgb:Int, alpha:Float):String
	{
		return 'rgba(' + RGBA.getR(rgb) + ',' + RGBA.getG(rgb) + ',' + RGBA.getB(rgb) + ',' + alpha + ')';
	}
	
	inline function getFillStyle(effect:Effect):String
	{
		if (effect.flags & EFFECT_COLOR_XFORM > 0)
		{
			var color =
			if (effect.alpha == 1)
				(0xff << 24) | effect.color;
			else
				(Std.int(effect.alpha * 0xff) << 24) | effect.color;
			
			color = effect.colorXForm.transformRGBA(color);
			return toRGBA(color & 0xffffff, (color >>> 24) / 0xff);
		}
		else
			return toRGBA(effect.color, effect.alpha);
	}
}

private class Tile
{
	//public var b:BitmapData;
	//public var r:Rectangle;
	
	public function new() {}
}