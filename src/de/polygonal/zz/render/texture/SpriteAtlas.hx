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
package de.polygonal.zz.render.texture;

import de.polygonal.zz.render.texture.Size;

class SpriteAtlas extends SpriteSheet
{
	public function new(tex:Tex, format:SpriteAtlasFormat, textureScale:Float = 1.)
	{
		super(tex, format.frameList.length);
		__spriteAtlas = this;
		
		for (i in 0...frameCount)
		{
			var frame = format.frameList[i];
			
			if (frame == null) continue;
			
			if (textureScale != 1)
			{
				frame = frame.clone();
				frame.x = Std.int(frame.x * textureScale);
				frame.y = Std.int(frame.y * textureScale);
				frame.w = Std.int(frame.w * textureScale);
				frame.h = Std.int(frame.h * textureScale);
				frame.r = frame.x + frame.w;
				frame.b = frame.y + frame.h;
			}
			
			var size = new Size(Std.int(frame.w), Std.int(frame.h));
			
			addCropRectAt(i, format.nameList[i], frame, size, tex.isNormalized);
			
			if (format.trimFlag[i])
			{
				_trimFlagList.set(i, true);
				_trimOffset.set(i, format.trimOffset[i]);
				_untrimmedSize.set(i, format.untrimmedSize[i]);
			}
			else
				_untrimmedSize.set(i, size);
		}
	}
}