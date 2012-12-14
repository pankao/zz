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
package de.polygonal.zz.render.module.swf.stage3d.paintbox;

import de.polygonal.zz.render.module.swf.stage3d.shader.AGALNullShader;
import de.polygonal.zz.render.module.swf.Stage3DRenderer;
import flash.display3D.Context3D;

class Stage3DBrushRectNull extends Stage3DBrushRect
{
	public function new(context:Context3D, effectMask:Int)
	{
		super(context, effectMask, -1);
		
		initVertexBuffer([2]);
		initIndexBuffer(1);
		
		_shader = new AGALNullShader(_context, effectMask);
	}
	
	override public function draw(renderer:Stage3DRenderer):Void
	{
		_shader.bindProgram();
		
		var constantRegisters = _scratchVector;
		var indexBuffer = _ib.handle;
		
		for (i in 0..._batch.size())
		{
			var mvp = renderer.setModelViewProjMatrix(_batch.get(i));
			mvp.m13 = 1; //op.zw
			mvp.toVector(constantRegisters);
			
			_context.setProgramConstantsFromVector(flash.display3D.Context3DProgramType.VERTEX, 0, constantRegisters, 2);
			_context.drawTriangles(indexBuffer, 0, 2);
			renderer.numCallsToDrawTriangle++;
		}
		
		super.draw(renderer);
	}
}