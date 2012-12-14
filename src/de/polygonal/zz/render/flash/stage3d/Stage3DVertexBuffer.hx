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
package de.polygonal.zz.render.flash.stage3d;

import de.polygonal.core.fmt.Sprintf;
import de.polygonal.core.math.Limits;
import de.polygonal.core.math.Vec3;
import flash.display3D.Context3D;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.VertexBuffer3D;
import flash.Vector;

class Stage3DVertexBuffer
{
	public var numFloatsPerVertex(default, null):Int;
	public var buffer(default, null):Vector<Float>;
	
	public var handle(default, null):VertexBuffer3D;
	
	var _context:Context3D;
	var _vertexBufferFormatLUT:Array<Context3DVertexBufferFormat>;
	
	var _size:Int;
	var _attributes:Vector<Int>;
	
	public function new(context:Context3D)
	{
		_context = context;
		_vertexBufferFormatLUT = [];
		_vertexBufferFormatLUT[0] = Context3DVertexBufferFormat.BYTES_4;
		_vertexBufferFormatLUT[1] = Context3DVertexBufferFormat.FLOAT_1;
		_vertexBufferFormatLUT[2] = Context3DVertexBufferFormat.FLOAT_2;
		_vertexBufferFormatLUT[3] = Context3DVertexBufferFormat.FLOAT_3;
		_vertexBufferFormatLUT[4] = Context3DVertexBufferFormat.FLOAT_4;
	}
	
	public function free():Void
	{
		buffer = null;
		
		if (handle != null)
		{
			handle.dispose();
			handle = null;
		}
		_context = null;
		_vertexBufferFormatLUT = null;
	}
	
	inline public function addFloat1(data:Vec3):Void
	{
		push(data.x);
	}
	
	inline public function addFloat2(data:Vec3):Void
	{
		push(data.x);
		push(data.y);
	}
	
	inline public function addFloat3(data:Vec3):Void
	{
		push(data.x);
		push(data.y);
		push(data.z);
	}
	
	inline public function addFloat4(data:Vec3):Void
	{
		push(data.x);
		push(data.y);
		push(data.z);
		push(data.w);
	}
	
	inline public function setFloat1(offset:Int, data:Vec3):Void
	{
		buffer[offset] = data.x;
	}
	
	inline public function setFloat2(offset:Int, data:Vec3):Void
	{
		buffer[offset + 0] = data.x;
		buffer[offset + 1] = data.y;
	}
	
	inline public function setFloat3(offset:Int, data:Vec3):Void
	{
		buffer[offset + 0] = data.x;
		buffer[offset + 1] = data.y;
		buffer[offset + 2] = data.z;
	}
	
	inline public function setFloat4(offset:Int, data:Vec3):Void
	{
		buffer[offset + 0] = data.x;
		buffer[offset + 1] = data.y;
		buffer[offset + 2] = data.z;
		buffer[offset + 3] = data.w;
	}
	
	inline function push(x:Float)
	{
		buffer[_size++] = x;
	}
	
	public function allocate(numFloatsPerAttribute:Array<Int>, numVertices:Int):Void
	{
		numFloatsPerVertex = 0;
		
		_attributes = new Vector();
		for (i in numFloatsPerAttribute)
		{
			numFloatsPerVertex += i;
			_attributes.push(i);
		}
		
		buffer = new Vector(numFloatsPerVertex * numVertices, true);
		_size = 0;
		
		if (handle != null) handle.dispose();
		
		#if verbose
		trace('allocate vertex buffer, numVertices: %d, numFloatsPerVertex: %d (%d)', numVertices, numFloatsPerVertex, numVertices * numFloatsPerVertex);
		#end
		
		handle = _context.createVertexBuffer(numVertices, numFloatsPerVertex);
	}
	
	public function upload(max = Limits.INT16_MAX):Void
	{
		var numVertices = Std.int(buffer.length / numFloatsPerVertex);
		if (numVertices > max) numVertices = max;
		handle.uploadFromVector(buffer, 0, numVertices);
		
		#if verbose
		trace('upload %d vertices', numVertices);
		#end
	}
	
	public function bind():Void
	{
		var index = 0;
		var bufferOffset = 0;
		var format = _vertexBufferFormatLUT;
		for (i in _attributes)
		{
			#if verbose
			//TODO
			//trace('set buffer: v%d, offset %d, size %d', index, bufferOffset, i);
			#end
			
			_context.setVertexBufferAt(index++, handle, bufferOffset, format[i]);
			bufferOffset += i;
		}
	}
	
	public function unbind():Void
	{
		for (i in 0..._attributes.length) _context.setVertexBufferAt(i, null);
	}
	
	public function toString():String
	{
		return Sprintf.format("{VertexBuffer: attributes=%s, #vertices=%d}", [_attributes.join(','), Std.int(_size / numFloatsPerVertex)]);
	}
}