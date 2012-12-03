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

import de.polygonal.ds.DA;

class SpriteSheet
{
	public var tex(default, null):Tex;
	
	var _cropMap:Hash<Rect>;
	var _sizeMap:Hash<Size>;
	
	var _sheetW:Int;
	var _sheetH:Int;
	
	public var __spriteStrip:SpriteStrip;
	public var __spriteAtlas:SpriteAtlas;
	
	function new(tex:Tex)
	{
		this.tex = tex;
		
		_cropMap = new Hash();
		_sizeMap = new Hash();
		
		_sheetW = tex.image.w;
		_sheetH = tex.image.h;
		
		__spriteStrip = null;
		__spriteAtlas = null;
	}
	
	public function free():Void
	{
		tex = null;
		
		_cropMap = null;
		_sizeMap = null;
		
		__spriteStrip = null;
		__spriteAtlas = null;
	}
	
	inline public function getSize(id:String):Size
	{
		return _sizeMap.get(id);
	}
	
	inline public function getCropRect(id:String):Rect
	{
		if (!_cropMap.exists(id)) throw 1;
		
		return _cropMap.get(id);
	}
	
	function addCropRectAt(index:Int, id:String, crop:Rect, normalize:Bool, pack:Bool)
	{
		crop = crop.clone();
		
		var size = new Size(Std.int(crop.w), Std.int(crop.h));
		
		_cropMap.set(id, crop);
		_cropMap.set(Std.string(index), crop);
		_sizeMap.set(id, size);
		_sizeMap.set(Std.string(index), size);
		
		if (pack)
		{
			crop.x += .5;
			crop.y += .5;
			crop.w -= 1.;
			crop.h -= 1.;
		}
		
		if (normalize)
		{
			crop.x /= tex.w;
			crop.y /= tex.h;
			crop.w /= tex.w;
			crop.h /= tex.h;
		}
		
		crop.r = crop.x + crop.w;
		crop.b = crop.y + crop.h;
	}
}