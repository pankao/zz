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

import de.polygonal.motor.geom.primitive.AABB2;
import de.polygonal.zz.render.text.BitmapFont;
import de.polygonal.zz.render.texture.SpriteAtlas;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.render.texture.thirdparty.BMFontFormat;
import de.polygonal.zz.scene.AlphaState;
import de.polygonal.zz.scene.Quad;
import de.polygonal.zz.scene.Renderer;

class FontEffect extends SpriteSheetEffect
{
	public var bitmapFont:BitmapFont;
	
	var tmp:Quad;
	
	public function new(tex:Tex, bitmapFont:BitmapFont)
	{
		this.bitmapFont = bitmapFont;
		
		tmp = new Quad();
		
		var format = new BMFontFormat(bitmapFont.characterSet);
		var atlas = new SpriteAtlas(tex, format);
		
		super(atlas);
	}
	
	public function setText(x:String, bound:AABB2 = null, align:Align = null, size:Float = -1)
	{
		if (bitmapFont.strings.size() > 0)
		{
			bitmapFont.updateString(0, x);
			return;
		}
		
		bitmapFont.addString(x, bound, align, size, 0xff0000, true);
	}
	
	override public function draw(renderer:Renderer):Void
	{
		var node = renderer.currNode;
		
		var q = tmp;
		
		node.addChild(q);
		
		renderer.setAlphaState(AlphaState.PREMULTIPLIED_ALPHA);
		
		for (quad in bitmapFont.quads)
		{
			var char = quad.bitmapChar;
			
			q.x = quad.X;
			q.y = quad.Y;
			q.scaleX = char.w * quad.sizeScale;
			q.scaleY = char.h * quad.sizeScale;
			q.updateGeometricState(true);
			
			this.frame = char.code;
			
			untyped renderer.currGeometry = q;
			untyped renderer.currEffect = this;
			
			renderer.drawSpriteSheetEffect(this);
		}
		
		renderer.setAlphaState(AlphaState.BLEND);
		
		node.removeChild(q);
	}
}