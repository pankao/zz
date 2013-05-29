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

import de.polygonal.zz.render.module.flash.stage3d.Stage3dIndexBuffer;
import de.polygonal.zz.render.module.flash.stage3d.Stage3dVertexBuffer;
import flash.display3D.Context3D;

class Stage3dBrushRect extends Stage3dBrush
{
	function new(context:Context3D, effectMask:Int, textureFlags:Int)
	{
		super(context, effectMask, textureFlags);
	}
	
	function initVertexBuffer(numQuads:Int, numFloatsPerAttribute:Array<Int>):Void
	{
		_vb = new Stage3dVertexBuffer(_context);
		_vb.allocate(numFloatsPerAttribute, numQuads * 4);
		for (i in 0...numQuads)
		{
			_vb.addFloat2f(0, 0);
			_vb.addFloat2f(1, 0);
			_vb.addFloat2f(1, 1);
			_vb.addFloat2f(0, 1);
		}
		
		_vb.upload();
	}
	
	function initIndexBuffer(numQuads:Int):Void
	{
		_ib = new Stage3dIndexBuffer(_context);
		for (i in 0...numQuads)
		{
			var offset = i << 2;
			
			_ib.add(offset + 0);
			_ib.add(offset + 1);
			_ib.add(offset + 2);
			
			_ib.add(offset + 0);
			_ib.add(offset + 2);
			_ib.add(offset + 3);
		}
		
		_ib.upload();
	}
}