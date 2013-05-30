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
package de.polygonal.zz.render.texture;

import de.polygonal.core.util.Assert;
import de.polygonal.zz.render.texture.SpriteSheet;

class SpriteStrip extends SpriteSheet
{
	public var frameW:Int;
	public var frameH:Int;
	
	public function new(tex:Tex, rows:Int, cols:Int)
	{
		super(tex, rows * cols);
		__spriteStrip = this;
		
		var w = _sheetW = tex.image.w;
		var h = _sheetH = tex.image.h;
		
		#if debug
		D.assert(w % cols == 0, 'w % cols == 0');
		D.assert(h % rows == 0, 'h % rows == 0');
		#end
		
		frameW = Std.int(w / cols);
		frameH = Std.int(h / rows);
		
		var offsetX = 0.;
		var offsetY = 0.;
		
		for (y in 0...rows)
		{
			for (x in 0...cols)
			{
				addCropRectAt(
					y * cols + x, x + '' + y,
					new Rect(offsetX + x * frameW, offsetY + y * frameH, frameW, frameH),
					new Size(frameW, frameH),
					tex.isNormalize);
			}
		}
	}
	
	override public function free():Void
	{
		super.free();
		frameW = -1;
		frameH = -1;
	}
}