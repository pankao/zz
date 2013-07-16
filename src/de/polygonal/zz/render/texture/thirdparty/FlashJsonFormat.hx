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
package de.polygonal.zz.render.texture.thirdparty;

import de.polygonal.zz.render.texture.Rect;
import de.polygonal.zz.render.texture.SpriteAtlasFormat;
import haxe.Json;

using Reflect;

class FlashJsonFormat extends SpriteAtlasFormat
{
	public function new(src:String)
	{
		super();
		
		var o:Dynamic = Json.parse(src);
		var frames:Dynamic = o.field('frames');
		
		for (frameName in frames.fields())
		{
			var frameData:Dynamic = frames.field(frameName);
			frameList.push(readRect(frameData, 'frame'));
			nameList.push(frameName);
		}
	}
	
	function readRect(o:Dynamic, name:String):Rect
	{
		var t:Dynamic = o.field(name);
		var frameX:Int = t.field('x');
		var frameY:Int = t.field('y');
		var frameW:Int = t.field('w');
		var frameH:Int = t.field('h');
		return new Rect(frameX, frameY, frameW, frameH);
	}
}