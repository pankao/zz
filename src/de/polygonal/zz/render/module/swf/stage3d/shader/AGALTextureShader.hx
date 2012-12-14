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
package de.polygonal.zz.render.module.swf.stage3d.shader;

import flash.display3D.Context3D;

class AGALTextureShader extends AGALShader
{
	public function new(context:Context3D, effectMask:Int, textureFlags:Int)
	{
		super(context, effectMask, textureFlags);
	}
	
	override function getVertexShader():String
	{
		//|r11 r12  a   tx| vc0
		//|r21 r22  1   ty| vc1
		//|uvw uvh uvx uvy| vc2
		//| -   -   -   - |
		
		var s = '';
		
		s += 'dp4 op.x, vc0, va0 \n';			//vertex * clip space row1
		s += 'dp4 op.y, vc1, va0 \n';			//vertex * clip space row2
		s += 'mov op.zw, vc1.z \n';				//z = 1, w = 1
		
		s += 'mul vt0, va0, vc2.xy \n';			//scale uv
		s += 'add vt0.xy, vt0.xy, vc2.zw \n';	//offset uv
		s += 'mov v0, vt0 \n';	 				//copy uv
		
		if (supportsAlpha())
			s += 'mov v1, vc0.z \n';			//copy alpha
		
		return s;
	}
	
	override function getFragmentShader():String
	{
		var s = '';
		
		s += 'tex ft0, v0, fs0 <TEX_FLAGS> \n';	//sample texture from uv
		
		if (supportsAlpha())
			s += 'mul ft0.w, v1, ft0 \n';		//* alpha
		
		if (supportsColorXForm())
		{
			s += 'mul ft0, ft0, fc0 \n';		//* color multiplier
			s += 'add ft0, fc1, ft0 \n';		//+ color offset
		}
		
		s += 'mov oc, ft0 \n';
		
		return s;
	}
}