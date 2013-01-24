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
package de.polygonal.zz.render.effect;

import de.polygonal.core.math.Vec3;
import de.polygonal.ds.Bits;
import de.polygonal.gl.color.ColorXForm;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.scene.Renderer;

using de.polygonal.ds.BitFlags;

class Effect
{
	inline public static var EFF_COLOR       = Bits.BIT_01;
	inline public static var EFF_TEXTURE     = Bits.BIT_02;
	inline public static var EFF_ALPHA       = Bits.BIT_03;
	inline public static var EFF_COLOR_XFORM = Bits.BIT_04;
	inline public static var EFF_MASK        = Bits.mask(4);
	
	inline static var UV_CHANGED         = Bits.BIT_05;
	inline static var ALPHA_CHANGED      = Bits.BIT_06;
	inline static var COLORXFORM_CHANGED = Bits.BIT_07;
	
	public static function print(flags:Int):String
	{
		var a = [];
		var i = 0;
		while (flags != 0 && i < 4)
		{
			if (flags & 1 != 0)
			{
				a.push(
				switch (i) 
				{
					case 0:  'color';
					case 1:  'texture';
					case 2:  'alpha';
					case 3:  'colorxform';
					default: 'unknown';
				});
			}
			flags >>= 1;
			i++;
		}
		return a.join(',');
	}
	
	public var flags(get_flags, never):Int;
	inline function get_flags():Int
	{
		return _bits & EFF_MASK;
	}
	
	public var color(get_color, set_color):Int;
	inline function get_color():Int
	{
		return _color;
	}
	inline function set_color(value:Int):Int
	{
		setf(EFF_COLOR);
		return _color = value;
	}
	
	public var alpha(get_alpha, set_alpha):Float;
	inline function get_alpha():Float
	{
		return _alpha;
	}
	inline function set_alpha(value:Float):Float
	{
		setfif(EFF_ALPHA, value < 1);
		setf(ALPHA_CHANGED);
		return _alpha = value;
	}
	
	public var colorXForm(get_colorXForm, set_colorXForm):ColorXForm;
	inline function get_colorXForm():ColorXForm
	{
		return _colorXForm;
	}
	inline function set_colorXForm(value:ColorXForm):ColorXForm
	{
		setfif(EFF_COLOR_XFORM, value != null);
		setf(COLORXFORM_CHANGED);
		return _colorXForm = value;
	}
	
	public var tex(get_tex, set_tex):Tex;
	inline function get_tex():Tex
	{
		return _tex;
	}
	inline function set_tex(value:Tex):Tex
	{
		setfif(EFF_TEXTURE, value != null);
		setfif(EFF_COLOR, value == null);
		return _tex = value;
	}
	
	#if (flash || nme)
	public var smooth:Bool = true;
	#end
	
	public var colors:Array<Vec3>;
	public var uv:Array<Vec3>;
	
	public var __textureEffect:TextureEffect;
	public var __spriteSheetEffect:SpriteSheetEffect;
	public var __textEffect:TextEffect;
	
	var _color:Int;
	var _colorXForm:ColorXForm;
	var _alpha:Float;
	var _tex:Tex;
	
	var _bits:Int;
	
	public function new()
	{
		_alpha = 1;
		_color = 0xff00ff;
		_bits = EFF_COLOR;
	}
	
	public function free():Void
	{
		colors = null;
		colorXForm = null;
		uv = null;
		
		_tex = null;
		
		__textureEffect = null;
		__spriteSheetEffect = null;
		__textEffect = null;
	}
	
	public function draw(renderer:Renderer):Void
	{
		renderer.drawEffect(this);
	}
	
	inline public function hasUVChanged():Bool
	{
		return hasf(UV_CHANGED);
	}
	
	inline public function hasAlphaChanged():Bool
	{
		return hasf(ALPHA_CHANGED);
	}
	
	inline public function hasColorXFormChanged():Bool
	{
		return hasf(COLORXFORM_CHANGED);
	}
	
	inline public function makeCurrent():Void
	{
		clrf(UV_CHANGED | ALPHA_CHANGED | COLORXFORM_CHANGED);
	}
}