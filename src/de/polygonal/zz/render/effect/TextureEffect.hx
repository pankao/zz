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
package de.polygonal.zz.render.effect;

import de.polygonal.core.math.Vec2;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.texture.Rect;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.scene.Renderer;

using de.polygonal.ds.BitFlags;

class TextureEffect extends Effect
{
	public var crop:Rect;
	
	public var uvOffsetX = 0.;
	public var uvOffsetY = 0.;
	
	public var uvScaleX = 1.;
	public var uvScaleY = 1.;
	
	public function new(tex:Tex)
	{
		super();
		__textureEffect = this;
		this.tex = tex;
		
		setCrop();
		setf(Effect.UV_CHANGED);
	}
	
	override public function free():Void
	{
		super.free();
		crop = null;
	}
	
	override public function draw(renderer:Renderer):Void
	{
		renderer.drawTextureEffect(this);
	}
	
	function setCrop():Void
	{
		var x:Float = 0, y:Float = 0, w:Float, h:Float;
		
		if (tex.isNormalize)
		{
			if (tex.isPowerOfTwo)
			{
				/*if (M.isPow2(tex.image.w))
				{
					
				}
				
				if (M.isPow2(tex.image.h))
				{
					
				}*/
				
				w = (tex.image.w) / (tex.w);
				h = (tex.image.h) / (tex.h);
				
				var tw = (w / tex.image.w);
				var th = (h / tex.image.h);
				
				x = tw/2;
				y = th/2;
				w = w - tw;
				h = h - th;
			}
			else
			{
				x = 0.;
				y = 0.;
				w = 1.;
				h = 1.;
			}
		}
		else
		{
			w = tex.image.w;
			h = tex.image.h;
		}
		
		crop = new Rect(x, y, w, h);
	}
}