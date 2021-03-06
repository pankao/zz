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
package de.polygonal.zz.render.module.flash.stage3d.shader;

import de.polygonal.ds.Bits;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.module.flash.stage3d.shader.util.AgalMiniAssembler;
import de.polygonal.zz.render.module.flash.stage3d.Stage3dTextureFlag;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Program3D;
import flash.display3D.textures.Texture;
import de.polygonal.core.util.Assert;

using de.polygonal.ds.Bits;

class AgalShader
{
	var _context:Context3D;
	var _program:Program3D;
	var _effectMask:Int;
	
	function new(context:Context3D, effectMask:Int, textureFlags:Int)
	{
		_context = context;
		_effectMask = effectMask;
		_program = null;
		
		if (textureFlags == 0)
		{
			initShaders(null);
			return;
		}
		
		#if debug
		D.assert(textureFlags > 0, 'textureFlags > 0');
		#end
		
		#if debug
		D.assert(textureFlags & (Stage3dTextureFlag.MM_NONE | Stage3dTextureFlag.MM_NEAREST | Stage3dTextureFlag.MM_LINEAR) > 0, 'mipmap flag missing');
		D.assert(textureFlags & (Stage3dTextureFlag.FM_NEAREST | Stage3dTextureFlag.FM_LINEAR) > 0, 'filtering flag missing');
		D.assert(textureFlags & (Stage3dTextureFlag.REPEAT_NORMAL | Stage3dTextureFlag.REPEAT_CLAMP) > 0, 'repeat flag missing');
		#end
		
		initShaders('2d,' + Stage3dTextureFlag.print(textureFlags));
	}
	
	public function free():Void
	{
		_program.dispose();
		_program = null;
		_context = null;
	}
	
	inline public function bindProgram():Void
	{
		_context.setProgram(_program);
	}
	
	inline public function bindTexture(samplerIndex:Int, texture:Texture):Void
	{
		_context.setTextureAt(samplerIndex, texture);
	}
	
	inline public function unbindTexture(samplerIndex:Int):Void
	{
		_context.setTextureAt(samplerIndex, null);
	}
	
	inline public function supportsAlpha():Bool
	{
		return _effectMask & Effect.EFFECT_ALPHA > 0;
	}
	
	inline public function supportsColorXForm():Bool
	{
		return _effectMask & Effect.EFFECT_COLOR_XFORM > 0;
	}
	
	inline public function hasPMA():Bool
	{
		return _effectMask & Effect.EFFECT_TEXTURE_PMA > 0;
	}
	
	function initShaders(texFlags:String)
	{
		var assembler = AgalMiniAssembler.get();
		
		assembler.assemble(cast Context3DProgramType.VERTEX, getVertexShader());
		
		var vertexShader = assembler.agalcode;
		
		var fragmentSource = getFragmentShader();
		if (texFlags != null)
			fragmentSource = StringTools.replace(fragmentSource, 'TEX_FLAGS', texFlags);
		
		assembler.assemble(cast Context3DProgramType.FRAGMENT, fragmentSource);
		
		var fragmentShader = assembler.agalcode;
		
		_program = _context.createProgram();
		_program.upload(vertexShader, fragmentShader);
	}
	
	function getVertexShader():String
	{
		return throw 'override for implementation';
	}
	
	function getFragmentShader():String
	{
		return throw 'override for implementation';
	}
}