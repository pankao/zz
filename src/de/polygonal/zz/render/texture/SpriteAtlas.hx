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

class SpriteAtlas extends SpriteSheet
{
	var _format:SpriteAtlasFormat;
	
	public function new(tex:Tex, format:SpriteAtlasFormat)
	{
		super(tex);
		__spriteAtlas = this;
		_format = format;
		
		frameCount = format.frameList.length;
		
		for (i in 0...frameCount)
		{
			var frame = format.frameList[i];
			if (frame != null) addCropRectAt(i, format.nameList[i], frame, tex.isNormalize);
		}
	}
	
	override public function free():Void
	{
		super.free();
		_format = null;
	}
	
	inline public function getTrimOffset(id:String):Size
	{
		return getTrimOffsetAt(getFrameIndex(id));
	}
	
	inline public function getTrimOffsetAt(index:Int):Size
	{
		D.assert(index >= 0 && index < _cropList.size(), 'index out of bound ($index)');
		
		return _format.trimOffset[index];
	}
	
	inline public function getUntrimmedSize(id:String):Size
	{
		return getUntrimmedSizeAt(getFrameIndex(id));
	}
	
	inline public function getUntrimmedSizeAt(index:Int):Size
	{
		D.assert(index >= 0 && index < _cropList.size(), 'index out of bound ($index)');
		
		return _format.untrimmedSize[index];
	}
}