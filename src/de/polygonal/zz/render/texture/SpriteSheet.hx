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
import de.polygonal.core.util.Assert;
import haxe.ds.StringMap;
import haxe.ds.IntMap;

class SpriteSheet
{
	public var tex(default, null):Tex;
	
	public var frameCount(default, null):Int;
	
	var _cropMap:StringMap<Rect>;
	var _sizeMap:StringMap<Size>;
	
	var _cropList:DA<Rect>;
	var _sizeList:DA<Size>;
	
	var _sheetW:Int;
	var _sheetH:Int;
	
	var _indexMap:StringMap<Int>;
	var _nameMap:IntMap<String>;
	
	public var __spriteStrip:SpriteStrip;
	public var __spriteAtlas:SpriteAtlas;
	
	function new(tex:Tex)
	{
		this.tex = tex;
		
		_cropMap = new StringMap();
		_sizeMap = new StringMap();
		
		_cropList = new DA<Rect>();
		_sizeList = new DA<Size>();
		
		_indexMap = new StringMap();
		_nameMap = new IntMap();
		
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
		
		_cropList = null;
		_sizeList = null;
		
		_indexMap = null;
		
		__spriteStrip = null;
		__spriteAtlas = null;
	}
	
	inline public function getSize(id:String):Size
	{
		return _sizeMap.get(id);
	}
	
	inline public function getSizeAt(index:Int):Size
	{
		return _sizeList.get(index);
	}
	
	inline public function getCropRect(id:String):Rect
	{
		#if debug
		D.assert(_cropMap.exists(id), '_cropMap.exists($id)');
		#end
		
		return _cropMap.get(id);
	}
	
	inline public function getCropRectAt(index:Int):Rect
	{
		return _cropList.get(index);
	}
	
	inline public function getFrameIndex(id:String):Int
	{
		#if debug
		D.assert(_indexMap.exists(id), '_indexMap.exists($id)');
		#end
		
		return _indexMap.get(id);
	}
	
	inline public function getFrameName(index:Int):String
	{
		#if debug
		D.assert(_nameMap.exists(index), '_nameMap.exists($index)');
		#end
		
		return _nameMap.get(index);
	}
	
	function addCropRectAt(index:Int, id:String, crop:Rect, normalize:Bool):Void
	{
		_indexMap.set(id, index);
		_nameMap.set(index, id);
		
		crop = crop.clone();
		
		var size = new Size(Std.int(crop.w), Std.int(crop.h));
		
		_cropMap.set(id, crop);
		_cropMap.set(cast index, crop);
		_sizeMap.set(id, size);
		_sizeMap.set(cast index, size);
		
		_cropList.set(index, crop);
		_sizeList.set(index, size);
		
		if (normalize)
		{
			crop.x += .5;
			crop.y += .5;
			crop.w -= 1.;
			crop.h -= 1.;
			
			crop.x /= tex.width;
			crop.y /= tex.height;
			crop.w /= tex.width;
			crop.h /= tex.height;
		}
		
		crop.r = crop.x + crop.w;
		crop.b = crop.y + crop.h;
	}
}