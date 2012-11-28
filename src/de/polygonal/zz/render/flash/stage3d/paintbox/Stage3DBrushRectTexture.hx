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
package de.polygonal.zz.render.flash.stage3d.paintbox;

import de.polygonal.zz.render.flash.stage3d.shader.AGALTextureShader;
import de.polygonal.zz.render.module.FlashStage3DRenderer;
import flash.display3D.Context3D;

class Stage3DBrushRectTexture extends Stage3DBrushRect
{
	inline static var INV_FF = .00392156;
	
	public function new(context:Context3D, effectMask:Int, textureFlags:Int)
	{
		super(context, effectMask, textureFlags);
		
		initVertexBuffer([2]);
		initIndexBuffer(1);
		
		_shader = new AGALTextureShader(_context, effectMask, textureFlags);
	}
	
	override public function draw(renderer:FlashStage3DRenderer):Void
	{
		var constantRegisters = _scratchVector;
		var indexBuffer = _ib.handle;
		
		_shader.bindProgram();
		_shader.bindTexture(0, renderer.currStage3DTexture.handle);
		
		for (i in 0..._batch.size())
		{
			var geometry = _batch.get(i);
			
			var mvp = renderer.setModelViewProjMatrix(renderer.currGeometry);
			var e = renderer.currEffect.__textureEffect;
			var crop = e.crop;
			
			mvp.m13 = e.alpha;
			mvp.m23 = 1; //op.zw
			mvp.m31 = crop.w;
			mvp.m32 = crop.h;
			mvp.m33 = crop.x;
			mvp.m34 = crop.y;
			mvp.toVector(constantRegisters);
			
			_context.setProgramConstantsFromVector(flash.display3D.Context3DProgramType.VERTEX, 0, constantRegisters, 3);
			
			if (_shader.supportsColorXForm())
			{
				var t = e.colorXForm.multiplier;
				constantRegisters[0] = t.r;
				constantRegisters[1] = t.g;
				constantRegisters[2] = t.b;
				constantRegisters[3] = t.a;
				
				t = e.colorXForm.offset;
				constantRegisters[4] = t.r * INV_FF;
				constantRegisters[5] = t.g * INV_FF;
				constantRegisters[6] = t.b * INV_FF;
				constantRegisters[7] = t.a * INV_FF;
				
				_context.setProgramConstantsFromVector(flash.display3D.Context3DProgramType.FRAGMENT, 0, constantRegisters, 2);
			}
			
			_context.drawTriangles(indexBuffer, 0, 2);
			renderer.numCallsToDrawTriangle++;
		}
		
		super.draw(renderer);
	}
}