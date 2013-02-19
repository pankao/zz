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
package de.polygonal.zz.render.module.flash.stage3d.paintbox;

import de.polygonal.zz.render.module.flash.stage3d.shader.AGALTextureShader;
import de.polygonal.zz.render.module.flash.stage3d.Stage3DRenderer;
import flash.display3D.Context3D;

class Stage3DBrushRectTexture extends Stage3DBrushRect
{
	inline static var INV_FF = .00392156;
	
	public function new(context:Context3D, effectMask:Int, textureFlags:Int)
	{
		super(context, effectMask, textureFlags);
		
		initVertexBuffer(1, [2]);
		initIndexBuffer(1);
		
		_shader = new AGALTextureShader(_context, effectMask, textureFlags);
	}
	
	override public function draw(renderer:Stage3DRenderer):Void
	{
		super.draw(renderer);
		
		var constantRegisters = _scratchVector;
		var indexBuffer = _ib.handle;
		
		var pma = _shader.hasPMA();
		var supportsColorXForm = _shader.supportsColorXForm();
		
		for (i in 0..._batch.size())
		{
			var geometry = _batch.get(i);
			
			var mvp = renderer.setModelViewProjMatrix(renderer.currGeometry);
			var e = renderer.currEffect.__textureEffect;
			var crop = e.crop;
			var alpha = e.alpha;
			
			mvp.m13 = alpha;
			mvp.m23 = 1; //op.zw
			mvp.m31 = crop.w * e.uvScaleX;
			mvp.m32 = crop.h * e.uvScaleY;
			mvp.m33 = crop.x + e.uvOffsetX;
			mvp.m34 = crop.y + e.uvOffsetY;
			mvp.toVector(constantRegisters);
			
			_context.setProgramConstantsFromVector(flash.display3D.Context3DProgramType.VERTEX, 0, constantRegisters, 3);
			
			if (supportsColorXForm)
			{
				var t = e.colorXForm.multiplier;
				if (pma)
				{
					var am = t.a;
					constantRegisters[0] = t.r * am * alpha;
					constantRegisters[1] = t.g * am * alpha;
					constantRegisters[2] = t.b * am * alpha;
					constantRegisters[3] = t.a * alpha;
				}
				else
				{
					constantRegisters[0] = t.r;
					constantRegisters[1] = t.g;
					constantRegisters[2] = t.b;
					constantRegisters[3] = t.a * alpha;
				}
				
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
		
		_batch.clear();
	}
}