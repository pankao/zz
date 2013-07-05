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

import de.polygonal.ds.HashableItem;

class Image extends HashableItem
{
	#if (flash || cpp)
	public static function ofData(data:flash.display.BitmapData)
	{
		return new Image(data, data.width, data.height, true);
	}
	#elseif js
	public static function ofData(data:js.w3c.html5.Core.HTMLImageElement)
	{
		return new Image(data, data.width, data.height, true);
	}
	#end
	
	public var id:String;
	public var data(default, null):ImageData;
	public var w(default, null):Int;
	public var h(default, null):Int;
	public var premultipliedAlpha:Bool;
	
	public function new(data:ImageData, w:Int, h:Int, premultipliedAlpha:Bool)
	{
		super();
		this.data = data;
		this.w = w;
		this.h = h;
		this.id = null;
		this.premultipliedAlpha = premultipliedAlpha;
	}
	
	public function clone():Image
	{
		#if (flash || cpp)
		return new Image(data.clone(), w, h, premultipliedAlpha);
		#end
		
		return throw 'unsupported operation';
	}
	
	public function free():Void
	{
		#if (flash || cpp)
		data.dispose();
		#end
		data = null;
		w = -1;
		h = -1;
		key = -1;
		id = null;
	}
}