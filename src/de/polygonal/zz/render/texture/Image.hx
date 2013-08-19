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

/*typedef ImgData<T> =
{
	var width:Int;
	var height:Int;
	var data:T;
}
*/
class Image extends de.polygonal.ds.HashableItem
{
	public static function ofData(data:ImageData):Image
	{
		return new Image(data, data.width, data.height, true);
	}

	#if flash11_4
	public static function ofBytes(data:flash.utils.ByteArray):Image
	{
		data.position = 0;

		if (data.readUTFBytes(3) != 'ATF') throw 'not an .atf file';

		//var tdata : UInt= data[6];
		//var type = tdata >> 7; 		// UB[1]
		//trace( "type : " + type );
		//var format = tdata & 0x7f;	// UB[7]
		//trace( "format : " + format );

		var format:flash.display3D.Context3DTextureFormat =
		switch (data[6])
		{
			case 0:
			case 1: flash.display3D.Context3DTextureFormat.BGRA;
			case 2:
			case 3: flash.display3D.Context3DTextureFormat.COMPRESSED;
			case 4: flash.display3D.Context3DTextureFormat.COMPRESSED_ALPHA;
			case 5: flash.display3D.Context3DTextureFormat.COMPRESSED_ALPHA;
			default: throw 'invalid atf format';
		}

		var w = 1 << data[7];
		var h = 1 << data[8];

		//num textures data[9];

		var image = new Image(null, w, h, false);
		data.position = 0;
		image.atf = data;
		image.atfFormat = format;

		return image;
	}
	#end
	
	public var id:String;
	public var data(default, null):ImageData;
	public var w(default, null):Int;
	public var h(default, null):Int;
	public var premultipliedAlpha:Bool;
	
	#if flash11_4
	public var atf:flash.utils.ByteArray;
	public var atfFormat:flash.display3D.Context3DTextureFormat;
	#end

	public function new(data:ImageData, w:Int, h:Int, premultipliedAlpha:Bool)
	{
		super();
		this.data = data;
		this.w = w;
		this.h = h;
		this.id = null;
		this.premultipliedAlpha = premultipliedAlpha;
	}
	
	#if flash11_4
	/*public function setATF(data:flash.utils.ByteArray)
	{

	}*/
	#end

	public function clone():Image
	{
		#if (flash || cpp)
		return new Image(data.clone(), w, h, premultipliedAlpha);
		#end
		
		return throw 'unsupported operation';
	}
	
	public function free()
	{
		#if (flash || cpp)
		data.dispose();
		#end
		data = null;

		#if flash11_4
		atf = null;
		#end

		w = -1;
		h = -1;
		key = -1;
		id = null;
	}
}