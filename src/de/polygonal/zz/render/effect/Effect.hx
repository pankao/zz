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
	inline public static var EFFECT_COLOR       = Bits.BIT_01;
	inline public static var EFFECT_TEXTURE     = Bits.BIT_02;
	inline public static var EFFECT_TEXTURE_PMA = Bits.BIT_03;
	inline public static var EFFECT_ALPHA       = Bits.BIT_04;
	inline public static var EFFECT_COLOR_XFORM = Bits.BIT_05;
	inline public static var EFFECT_SMOOTH      = Bits.BIT_06;
	inline public static var EFFECT_MASK        = Bits.mask(6);
	
	inline static var UV_CHANGED             = Bits.BIT_07;
	inline static var ALPHA_CHANGED          = Bits.BIT_08;
	inline static var COLORXFORM_CHANGED     = Bits.BIT_09;
	
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
					case 0: 'color';
					case 1: 'texture (straight alpha)';
					case 2: 'texture (premultiplied alpha)';
					case 3: 'alpha';
					case 4: 'colorxform';
					case 5: 'smooth';
					default: '?';
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
		return _bits & EFFECT_MASK;
	}
	
	public var color(get_color, set_color):Int;
	inline function get_color():Int
	{
		return _color;
	}
	inline function set_color(value:Int):Int
	{
		setf(EFFECT_COLOR);
		return _color = value;
	}
	
	public var alpha(get_alpha, set_alpha):Float;
	inline function get_alpha():Float
	{
		return _alpha;
	}
	inline function set_alpha(value:Float):Float
	{
		setfif(EFFECT_ALPHA, value < 1);
		setf(ALPHA_CHANGED);
		return _alpha = value;
	}
	
	public var colorXForm(get_colorXForm, set_colorXForm):ColorXForm;
	inline function get_colorXForm():ColorXForm
	{
		setf(EFFECT_COLOR_XFORM);
		return _colorXForm;
	}
	function set_colorXForm(value:ColorXForm):ColorXForm
	{
		if (value != null)
		{
			setf(EFFECT_COLOR_XFORM);
			_colorXForm = value;
		}
		else
		{
			clrf(EFFECT_COLOR_XFORM);
			_colorXForm = null;
		}
		
		setf(COLORXFORM_CHANGED);
		return value;
	}
	
	public var tex(get_tex, set_tex):Tex;
	inline function get_tex():Tex
	{
		return _tex;
	}
	function set_tex(value:Tex):Tex
	{
		if (value != null)
		{
			if (value.isAlphaPreMultiplied)
				setf(EFFECT_TEXTURE_PMA);
			else
				setf(EFFECT_TEXTURE);
			clrf(EFFECT_COLOR);
		}
		else
		{
			clrf(EFFECT_TEXTURE | EFFECT_TEXTURE_PMA);
			setf(EFFECT_COLOR);
		}
		
		return _tex = value;
	}
	
	public var smooth(get_smooth, set_smooth):Bool;
	inline function get_smooth():Bool
	{
		return hasf(EFFECT_SMOOTH);
	}
	inline function set_smooth(value:Bool):Bool
	{
		setfif(EFFECT_SMOOTH, value);
		return value;
	}
	
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
		_colorXForm = new ColorXForm();
		_bits = EFFECT_COLOR | EFFECT_SMOOTH;
	}
	
	public function free():Void
	{
		colors = null;
		_colorXForm = null;
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
	
	inline public function hasTexture():Bool
	{
		return hasf(EFFECT_TEXTURE | EFFECT_TEXTURE_PMA);
	}
	
	/*inline public function hasUVChanged():Bool
	{
		return hasf(UV_CHANGED);
	}*/
	
	/*inline public function hasAlphaChanged():Bool
	{
		return hasf(ALPHA_CHANGED);
	}*/
	
	/*inline public function hasColorXFormChanged():Bool
	{
		return hasf(COLORXFORM_CHANGED);
	}*/
	
	/*inline public function makeCurrent():Void
	{
		clrf(UV_CHANGED | ALPHA_CHANGED | COLORXFORM_CHANGED);
	}*/
}