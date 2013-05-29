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

import de.polygonal.zz.render.module.flash.stage3d.shader.AgalSolidColor;
import de.polygonal.zz.render.module.flash.stage3d.Stage3dRenderer;
import flash.display3D.Context3D;

using de.polygonal.gl.color.RGBA;

class Stage3dBrushRectSolidColor extends Stage3dBrushRect
{
	inline static var INV_FF = .00392156;
	
	public function new(context:Context3D, effectMask:Int)
	{
		super(context, effectMask, -1);
		
		initVertexBuffer(1, [2]);
		initIndexBuffer(1);
		
		_shader = new AgalSolidColor(_context, effectMask);
	}
	
	override public function draw(renderer:Stage3dRenderer):Void
	{
		super.draw(renderer);
		
		var constantRegisters = _scratchVector;
		var indexBuffer = _ib.handle;
		
		for (i in 0..._batch.size())
		{
			var geometry = _batch.get(i);
			var mvp = renderer.setModelViewProjMatrix(geometry);
			mvp.m13 = 1; //op.zw
			mvp.toVector(constantRegisters);
			
			_context.setProgramConstantsFromVector(flash.display3D.Context3DProgramType.VERTEX, 0, constantRegisters, 2);
			
			var e = geometry.effect;
			var c = e.color;
			var r = c.getR();
			var g = c.getG();
			var b = c.getB();
			var a = e.alpha;
			if (e.colorXForm != null)
			{
				var m = e.colorXForm.multiplier;
				var o = e.colorXForm.offset;
				constantRegisters[0] = (r * m.r + o.r) * INV_FF;
				constantRegisters[1] = (g * m.g + o.g) * INV_FF;
				constantRegisters[2] = (b * m.b + o.b) * INV_FF;
				constantRegisters[3] =  a * m.a + (o.a * INV_FF);
			}
			else
			{
				constantRegisters[0] = r * INV_FF;
				constantRegisters[1] = g * INV_FF;
				constantRegisters[2] = b * INV_FF;
				constantRegisters[3] = e.alpha;
			}
			
			_context.setProgramConstantsFromVector(flash.display3D.Context3DProgramType.FRAGMENT, 0, constantRegisters, 1);
			_context.drawTriangles(indexBuffer, 0, 2);
			renderer.numCallsToDrawTriangle++;
		}
		
		_batch.clear();
	}
}