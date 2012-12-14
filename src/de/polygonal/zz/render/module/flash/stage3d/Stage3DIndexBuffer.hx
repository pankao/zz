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
package de.polygonal.zz.render.module.flash.stage3d;

import de.polygonal.core.fmt.Sprintf;
import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.Vector;

class Stage3DIndexBuffer
{
	public var numIndices(default, null):Int;
	
	public var numTriangles(get_numTriangles, never):Int;
	function get_numTriangles():Int
	{
		return Std.int(numIndices / 3);
	}
	
	public var handle:IndexBuffer3D;
	
	var _context:Context3D;
	var _buffer:Vector<UInt>;
	
	public function new(context:Context3D)
	{
		_buffer = new Vector();
		numIndices = 0;
		
		_context = context;
	}
	
	public function free():Void
	{
		handle.dispose();
		handle = null;
		
		_buffer = null;
		_context = null;
	}
	
	inline public function clear():Void
	{
		numIndices = 0;
	}
	
	inline public function add(i:Int):Void
	{
		_buffer[numIndices++] = i;
	}
	
	public function upload(?count = -1):Void
	{
		if (count == -1) count = numIndices;
		
		if (handle == null)
			handle = _context.createIndexBuffer(count);
		else
		{
			handle.dispose();
			handle = _context.createIndexBuffer(count);
		}
		
		handle.uploadFromVector(_buffer, 0, count);
	}
	
	public function toString():String
	{
		return Sprintf.format("{IndexBuffer: #indices=%d, #triangles=%d}", [numIndices, numTriangles]);
	}
}