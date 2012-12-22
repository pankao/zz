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

import de.polygonal.core.math.Vec3;
import de.polygonal.zz.render.module.flash.stage3d.shader.AGALSolidColorConstantBatch;
import de.polygonal.zz.render.module.flash.stage3d.shader.AGALSolidColorVertexBatch;
import de.polygonal.zz.render.module.flash.stage3d.shader.AGALSolidColorVertexBatch;
import de.polygonal.zz.render.module.flash.stage3d.shader.AGALTextureConstantBatch;
import de.polygonal.zz.render.module.flash.stage3d.Stage3DRenderer;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;

using de.polygonal.ds.BitFlags;
using de.polygonal.gl.color.RGBA;

class Stage3DBrushRectSolidColorBatch extends Stage3DBrushRect
{
	inline static var INV_FF = .00392156;
	inline static var MAX_SUPPORTED_REGISTERS = 128;
	inline static var NUM_FLOATS_PER_REGISTER = 4;
	
	public static var MAX_BATCH_SIZE_QUADS = 4096;
	
	var _numSharedRegisters:Int;
	var _numRegistersPerQuad:Int;
	var _strategy:Int;
	
	public function new(context:Context3D, effectMask:Int, textureFlags:Int)
	{
		super(context, effectMask, textureFlags);
		
		_strategy = Stage3DRenderer.BATCH_STRATEGY;
		
		_batchCapacity = MAX_BATCH_SIZE_QUADS;
		
		if (_strategy == Stage3DRenderer.VERTEX_BATCH)
		{
			_shader = new AGALSolidColorVertexBatch(_context, effectMask);
			
			var numFloatsPerAttribute = [2, 4];
			_vb = new Stage3DVertexBuffer(_context);
			_vb.allocate(numFloatsPerAttribute, _batchCapacity * 4);
		}
		else
		if (_strategy == Stage3DRenderer.CONSTANT_BATCH)
		{
			_shader = new AGALSolidColorConstantBatch(_context, effectMask);
			
			_numSharedRegisters = 0;
			_numRegistersPerQuad = 3;
			
			_scratchVector.length = MAX_SUPPORTED_REGISTERS * NUM_FLOATS_PER_REGISTER;
			_scratchVector.fixed = true;
			
			var maxBatchSize:Int = cast ((MAX_SUPPORTED_REGISTERS - _numSharedRegisters) / _numRegistersPerQuad);
			if (_batchCapacity > maxBatchSize) _batchCapacity = maxBatchSize;
			
			_vb = new Stage3DVertexBuffer(_context);
			_vb.allocate([2, 3], maxBatchSize * 4); //uv, index
			
			var vertices = [new Vec3(0, 0), new Vec3(1, 0), new Vec3(1, 1), new Vec3(0, 1)];
			var address3 = new Vec3();
			for (i in 0...maxBatchSize)
			{
				var constRegIndex = _numSharedRegisters + i * _numRegistersPerQuad;
				address3.x = constRegIndex + 0;
				address3.y = constRegIndex + 1;
				address3.z = constRegIndex + 2;
				
				for (i in 0...4)
				{
					_vb.addFloat2(vertices[i]);
					_vb.addFloat3(address3);
				}
			}
		}
		
		initIndexBuffer(_batchCapacity);
		
		_ib.upload();
		_vb.upload();
	}
	
	override public function draw(renderer:Stage3DRenderer):Void
	{
		super.draw(renderer);
		
		var constantRegisters = _scratchVector;
		
		if (_strategy == 0) //"vertex batching"
		{
			updateVertexBuffer();
			
			var vp = renderer.currViewProjMatrix;
			vp.m13 = 1; //op.zw
			vp.toVector(constantRegisters);
			
			_context.setProgramConstantsFromVector(flash.display3D.Context3DProgramType.VERTEX, 0, constantRegisters, 2);
			
			_context.drawTriangles(_ib.handle, 0, _batch.size() << 1);
			renderer.numCallsToDrawTriangle++;
		}
		else
		if (_strategy == 1) //"constant batching"
		{
			var changed = false;
			var stride = _vb.numFloatsPerVertex;
			for (i in 0..._batch.size())
			{
				var g = _batch.get(i);
				if (g.hasModelChanged())
				{
					changed = true;
					var address = (i << 2) * stride;
					_vb.setFloat2(address, g.vertices[0]); address += stride;
					_vb.setFloat2(address, g.vertices[1]); address += stride;
					_vb.setFloat2(address, g.vertices[2]); address += stride;
					_vb.setFloat2(address, g.vertices[3]);
				}
			}
			
			if (changed) _vb.upload();
			
			var batch = _batch;
			var size = batch.size();
			
			var geometry, effect, mvp;
			var offset;
			var capacity = _batchCapacity;
			var fullPasses:Int = cast size / capacity;
			var remainder = size % capacity;
			var next = 0;
			for (pass in 0...fullPasses)
			{
				for (i in 0...capacity)
				{
					geometry = batch.get(next++);
					effect = geometry.effect;
					
					mvp = renderer.setModelViewProjMatrix(geometry);
					
					//use 2 constant registers (each 4 floats) for mvp matrix and alpha (+2 constant registers for color transform)
					offset = (_numSharedRegisters * NUM_FLOATS_PER_REGISTER) + i * (_numRegistersPerQuad * NUM_FLOATS_PER_REGISTER);
					
					constantRegisters[offset +  0] = mvp.m11;
					constantRegisters[offset +  1] = mvp.m12;
					constantRegisters[offset +  2] = 1; //op.zw = 1
					constantRegisters[offset +  3] = mvp.m14;
					
					constantRegisters[offset +  4] = mvp.m21;
					constantRegisters[offset +  5] = mvp.m22;
					constantRegisters[offset +  6] = 1; //unused
					constantRegisters[offset +  7] = mvp.m24;
					
					var c = effect.color;
					var r = c.getR();
					var g = c.getG();
					var b = c.getB();
					var a = effect.alpha;
					if (effect.colorXForm != null)
					{
						var m = effect.colorXForm.multiplier;
						var o = effect.colorXForm.offset;
						constantRegisters[offset +  8] = (r * m.r + o.r) * INV_FF;
						constantRegisters[offset +  9] = (g * m.g + o.g) * INV_FF;
						constantRegisters[offset + 10] = (b * m.b + o.b) * INV_FF;
						constantRegisters[offset + 11] =  a * m.a + (o.a * INV_FF);
					}
					else
					{
						constantRegisters[offset +  8] = r * INV_FF;
						constantRegisters[offset +  9] = g * INV_FF;
						constantRegisters[offset + 10] = b * INV_FF;
						constantRegisters[offset + 11] = a;
					}
				}
				
				_context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, constantRegisters,
					_numSharedRegisters + capacity * _numRegistersPerQuad);
				_context.drawTriangles(_ib.handle, 0, capacity << 1);
				renderer.numCallsToDrawTriangle++;
			}
			
			if (remainder > 0)
			{
				for (i in 0...remainder)
				{
					geometry = batch.get(next++);
					effect = geometry.effect;
					mvp = renderer.setModelViewProjMatrix(geometry);
					offset = (_numSharedRegisters * NUM_FLOATS_PER_REGISTER) + i * (_numRegistersPerQuad * NUM_FLOATS_PER_REGISTER);
					constantRegisters[offset +  0] = mvp.m11;
					constantRegisters[offset +  1] = mvp.m12;
					constantRegisters[offset +  2] = 1;
					constantRegisters[offset +  3] = mvp.m14;
					
					constantRegisters[offset +  4] = mvp.m21;
					constantRegisters[offset +  5] = mvp.m22;
					constantRegisters[offset +  6] = 1;
					constantRegisters[offset +  7] = mvp.m24;
					
					var c = effect.color;
					var r = c.getR();
					var g = c.getG();
					var b = c.getB();
					var a = effect.alpha;
					if (effect.colorXForm != null)
					{
						var m = effect.colorXForm.multiplier;
						var o = effect.colorXForm.offset;
						constantRegisters[offset +  8] = (r * m.r + o.r) * INV_FF;
						constantRegisters[offset +  9] = (g * m.g + o.g) * INV_FF;
						constantRegisters[offset + 10] = (b * m.b + o.b) * INV_FF;
						constantRegisters[offset + 11] =  a * m.a + (o.a * INV_FF);
					}
					else
					{
						constantRegisters[offset +  8] = r * INV_FF;
						constantRegisters[offset +  9] = g * INV_FF;
						constantRegisters[offset + 10] = b * INV_FF;
						constantRegisters[offset + 11] = a;
					}
				}
				
				_context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, constantRegisters,
					_numSharedRegisters + remainder * _numRegistersPerQuad);
				_context.drawTriangles(_ib.handle, 0, remainder * 2);
				renderer.numCallsToDrawTriangle++;
			}
		}
		
		_batch.clear();
	}
	
	function updateVertexBuffer()
	{
		var stride = _vb.numFloatsPerVertex;
		
		var t = _scratchVec3;
		var vb = _vb;
		var batch = _batch;
		
		var offset, address, i, size;
		var geometry, effect, vertices, world;
		
		size = batch.size();
		
		i = 0;
		size = batch.size();
		while (i < size)
		{
			offset = (i << 2) * stride;
			
			geometry = batch.get(i);
			effect = geometry.effect;
			
			//update vertices
			vertices = geometry.vertices;
			world = geometry.world;
			address = offset;
			vb.setFloat2(address, world.applyForward2(vertices[0], t)); address += stride;
			vb.setFloat2(address, world.applyForward2(vertices[1], t)); address += stride;
			vb.setFloat2(address, world.applyForward2(vertices[2], t)); address += stride;
			vb.setFloat2(address, world.applyForward2(vertices[3], t));
			
			offset += 2;
			
			var c = effect.color;
			var r = c.getR();
			var g = c.getG();
			var b = c.getB();
			var a = effect.alpha;
			if (effect.colorXForm != null)
			{
				var m = effect.colorXForm.multiplier;
				var o = effect.colorXForm.offset;
				t.x = (r * m.r + o.r) * INV_FF;
				t.y = (g * m.g + o.g) * INV_FF;
				t.z = (b * m.b + o.b) * INV_FF;
				t.w =  a * m.a + (o.a * INV_FF);
			}
			else
			{
				t.x = r * INV_FF;
				t.y = g * INV_FF;
				t.z = b * INV_FF;
				t.w = a;
			}
			
			address = offset;
			vb.setFloat4(address, t); address += stride;
			vb.setFloat4(address, t); address += stride;
			vb.setFloat4(address, t); address += stride;
			vb.setFloat4(address, t);
			
			i++;
		}
		
		vb.upload(size << 2);
	}
}