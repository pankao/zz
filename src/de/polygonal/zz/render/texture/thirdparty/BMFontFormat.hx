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
package de.polygonal.zz.render.texture.thirdparty;

import de.polygonal.core.fmt.Sprintf;
import de.polygonal.core.math.Limits;
import de.polygonal.core.math.Mathematics;
import de.polygonal.ds.ArrayUtil;
import de.polygonal.ds.Bits;
import de.polygonal.zz.render.texture.Rect;
import de.polygonal.zz.render.texture.SpriteAtlasFormat;

#if haxe3
import haxe.ds.IntMap in IntHash;
#end

using Std;

class BMFontFormat extends SpriteAtlasFormat
{
	public var charSet(default, null):BitmapCharSet;
	
	public function new(src:String)
	{
		super();
		
		try
		{
			var fast = new haxe.xml.Fast(Xml.parse(src).firstElement());
			
			charSet              = new BitmapCharSet();
			charSet.renderedSize = M.abs(fast.node.info.att.size.parseInt());
			charSet.lineHeight   = fast.node.common.att.lineHeight.parseInt();
			charSet.base         = fast.node.common.att.base.parseInt();
			charSet.textureW     = fast.node.common.att.scaleW.parseInt();
			charSet.textureH     = fast.node.common.att.scaleH.parseInt();
			
			sheetWidth = charSet.textureW;
			sheetHeight = charSet.textureH;
			
			var minCode = Limits.INT16_MAX;
			var maxCode = -1;
			for (e in fast.node.chars.nodes.char)
			{
				var code = e.att.id.parseInt();
				if (code > maxCode) maxCode = code;
				if (code < minCode) minCode = code;
			}
			
			for (i in 0...maxCode)
			{
				frameList[i] = new Rect(0, 0, 1, 1);
				nameList[i] = 'undefined';
			}
			
			for (e in fast.node.chars.nodes.char)
			{
				var code = e.att.id.parseInt();
				
				var char     = new BitmapChar();
				char.code    = code;
				char.x       = e.att.x.parseInt();
				char.y       = e.att.y.parseInt();
				char.offX    = e.att.xoffset.parseInt();
				char.offY    = e.att.yoffset.parseInt();
				char.stepX   = e.att.xadvance.parseInt();
				char.w       = e.att.width.parseInt();
				char.h       = e.att.height.parseInt();
				charSet.characters[char.code] = char;
				
				if (code == -1) continue;
				
				var crop = new Rect(char.x, char.y, char.w, char.h);
				frameList[code] = crop;
				nameList[code] = String.fromCharCode(code);
			}
			
			charSet.kerning = new IntHash();
			
			for (e in fast.node.kernings.nodes.kerning)
			{
				var first  = e.att.first.parseInt();
				var second = e.att.second.parseInt();
				var amount = e.att.amount.parseInt();
				charSet.kerning.set(Bits.packUI16(first, second), amount);
			}
		}
		catch (error:Dynamic)
		{
			trace('invalid xml file: ' + error);
		}
	}
	
	public function free():Void
	{
		if (charSet != null)
		{
			charSet.free();
			charSet = null;
		}
	}
}

class BitmapChar
{
	public var code = -1;
	public var x = 0;
	public var y = 0;
	public var offX = 0;
	public var offY = 0;
	public var stepX = 0;
	public var w = 0;
	public var h = 0;
	
	public function new() {}
}

class BitmapCharSet
{
	public var renderedSize:Int;
	public var characters:Array<BitmapChar>;
	public var kerning:IntHash<Int>;
	public var textureW:Int;
	public var textureH:Int;
	
	public var lineHeight:Int;
	public var base:Int;
	
	public function new() 
	{
		characters = ArrayUtil.alloc(256);
		ArrayUtil.assign(characters, BitmapChar, [], 256);
		kerning = new IntHash<Int>();
	}
	
	public function free():Void
	{
		characters = null;
		kerning = null;
	}
	
	public function toString():String
	{
		return Sprintf.format("{BitmapCharSet: lineHeight=%d, base=%d, renderedSize=%d, textureW=%d, textureH=%d",
			[lineHeight, base, renderedSize, textureW, textureH]);
	}
}