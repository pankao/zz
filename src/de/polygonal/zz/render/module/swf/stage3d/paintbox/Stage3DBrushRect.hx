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

import de.polygonal.core.math.Vec3;
import de.polygonal.zz.render.module.swf.stage3d.Stage3DIndexBuffer;
import de.polygonal.zz.render.module.swf.stage3d.Stage3DVertexBuffer;
import flash.display3D.Context3D;

class Stage3DBrushRect extends Stage3DBrush
{
	public function new(context:Context3D, effectMask:Int, textureFlags:Int)
	{
		super(context, effectMask, textureFlags);
	}
	
	function initVertexBuffer(numFloatsPerAttribute:Array<Int>)
	{
		_vb = new Stage3DVertexBuffer(_context);
		_vb.allocate(numFloatsPerAttribute, 4);
		_vb.addFloat2(new Vec3(0, 0));
		_vb.addFloat2(new Vec3(1, 0));
		_vb.addFloat2(new Vec3(1, 1));
		_vb.addFloat2(new Vec3(0, 1));
		_vb.upload();
	}
	
	function initIndexBuffer(numQuads:Int)
	{
		_ib = new Stage3DIndexBuffer(_context);
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