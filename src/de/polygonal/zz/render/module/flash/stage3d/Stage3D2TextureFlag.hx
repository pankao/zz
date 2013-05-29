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
package de.polygonal.zz.render.module.flash.stage3d;

import de.polygonal.ds.Bits;

class Stage3dTextureFlag
{
	inline public static var MM_NONE       = Bits.BIT_10;
	inline public static var MM_NEAREST    = Bits.BIT_11;
	inline public static var MM_LINEAR     = Bits.BIT_12;
	inline public static var FM_NEAREST    = Bits.BIT_13;
	inline public static var FM_LINEAR     = Bits.BIT_14;
	inline public static var REPEAT_NORMAL = Bits.BIT_15;
	inline public static var REPEAT_CLAMP  = Bits.BIT_16;
	inline public static var DXT1          = Bits.BIT_17;
	inline public static var DXT5          = Bits.BIT_18;
	
	inline public static var PRESET_QUALITY_LOW    = MM_NONE    | FM_NEAREST | REPEAT_NORMAL;
	inline public static var PRESET_QUALITY_MEDIUM = MM_NONE    | FM_LINEAR  | REPEAT_NORMAL;
	inline public static var PRESET_QUALITY_HIGH   = MM_NEAREST | FM_LINEAR  | REPEAT_NORMAL;
	inline public static var PRESET_QUALITY_ULTRA  = MM_LINEAR  | FM_LINEAR  | REPEAT_NORMAL;
	
	public static function print(flags:Int):String
	{
		if (flags <= 0) return '-';
		
		var a = [];
		for (i in 0...9)
		{
			if ((flags >> 9) & (1 << i) > 0)
			{
				a.push(
				switch (i) 
				{
					case 0: 'mipnone';
					case 1: 'mipnearest';
					case 2: 'miplinear';
					case 3: 'nearest';
					case 4: 'linear';
					case 5: 'repeat';
					case 6: 'clamp';
					case 7: 'dxt1';
					case 8: 'dxt5';
					default: throw 'unknown texture flag';
				});
			}
		}
		return a.join(',');
	}
}