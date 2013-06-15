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
import de.polygonal.zz.render.module.flash.stage3d.shader.AgalTextureConstantBatch;
import de.polygonal.zz.render.module.flash.stage3d.shader.AgalTextureVertexBatch;
import de.polygonal.zz.render.module.flash.stage3d.Stage3dRenderer;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;

using de.polygonal.ds.BitFlags;

class Stage3dBrushRectTextureBatch extends Stage3dBrushRect
{
	inline static var INV_FF = .00392156;
	inline static var MAX_SUPPORTED_REGISTERS = 128;
	inline static var NUM_FLOATS_PER_REGISTER = 4;
	
	var _numSharedRegisters:Int;
	var _numRegistersPerQuad:Int;
	var _strategy:Int;
	var _scratchVertices:Array<Vec3>;
	
	var _uv0:Vec3;
	var _uv1:Vec3;
	var _uv2:Vec3;
	var _uv3:Vec3;
	var _uvs:Array<Vec3>;
	
	public function new(renderer:Stage3dRenderer, context:Context3D, effectMask:Int, textureFlags:Int)
	{
		super(context, effectMask, textureFlags);
		
		_strategy = renderer.batchStrategy;
		_batchCapacity = renderer.maxBatchSize;
		
		_scratchVertices = [new Vec3(0, 0), new Vec3(1, 0), new Vec3(1, 1), new Vec3(0, 1)];
		
		_uv0 = new Vec3();
		_uv1 = new Vec3();
		_uv2 = new Vec3();
		_uv3 = new Vec3();
		_uvs = [_uv0, _uv1, _uv2, _uv3];
		
		if (_strategy == 0) //0=use vertex buffer
		{
			_shader = new AgalTextureVertexBatch(_context, effectMask, textureFlags);
			
			var numFloatsPerAttribute = [2, 2];
			
			if (_shader.supportsAlpha()) numFloatsPerAttribute.push(1);
			if (_shader.supportsColorXForm())
			{
				numFloatsPerAttribute.push(4);
				numFloatsPerAttribute.push(4);
			}
			
			_vb = new Stage3dVertexBuffer(_context);
			_vb.allocate(numFloatsPerAttribute, _batchCapacity * 4);
		}
		else
		if (_strategy == 1) //1=use constant registers
		{
			_shader = new AgalTextureConstantBatch(_context, effectMask, textureFlags);
			
			_numSharedRegisters = 0;
			_numRegistersPerQuad = _shader.supportsColorXForm() ? 5 : 3;
			
			_scratchVector.length = MAX_SUPPORTED_REGISTERS * NUM_FLOATS_PER_REGISTER;
			_scratchVector.fixed = true;
			
			var maxBatchSize:Int = cast ((MAX_SUPPORTED_REGISTERS - _numSharedRegisters) / _numRegistersPerQuad);
			if (_batchCapacity > maxBatchSize) _batchCapacity = maxBatchSize;
			
			_vb = new Stage3dVertexBuffer(_context);
			_vb.allocate(_shader.supportsColorXForm() ? [2, 3, 2] : [2, 3], maxBatchSize * 4);
			
			var address3 = new Vec3();
			var address2 = new Vec3();
			for (i in 0...maxBatchSize)
			{
				var constRegIndex = _numSharedRegisters + i * _numRegistersPerQuad;
				address3.x = constRegIndex + 0;
				address3.y = constRegIndex + 1;
				address3.z = constRegIndex + 2;
				
				if (_shader.supportsColorXForm())
				{
					address2.x = constRegIndex + 3;
					address2.y = constRegIndex + 4;
					
					for (i in 0...4)
					{
						_vb.addFloat2(_scratchVertices[i]);
						_vb.addFloat3(address3);
						_vb.addFloat2(address2);
					}
				}
				else
				{
					for (i in 0...4)
					{
						_vb.addFloat2(_scratchVertices[i]);
						_vb.addFloat3(address3);
					}
				}
			}
		}
		
		initIndexBuffer(_batchCapacity);
		
		_ib.upload();
		_vb.upload();
	}
	
	override public function free():Void
	{
		super.free();
		
		_uv0 = null;
		_uv1 = null;
		_uv2 = null;
		_uv3 = null;
		_uvs = null;
	}
	
	override public function draw(renderer:Stage3dRenderer):Void
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
			var geometry;
			var changed = false;
			var stride = _vb.numFloatsPerVertex;
			for (i in 0..._batch.size())
			{
				geometry = _batch.get(i);
				if (geometry.hasModelChanged())
				{
					changed = true;
					var address = (i << 2) * stride;
					_vb.setFloat2(address, geometry.vertices[0]); address += stride;
					_vb.setFloat2(address, geometry.vertices[1]); address += stride;
					_vb.setFloat2(address, geometry.vertices[2]); address += stride;
					_vb.setFloat2(address, geometry.vertices[3]);
				}
			}
			
			if (changed) _vb.upload();
			
			var batch = _batch;
			var size = batch.size();
			
			var supportsColorXForm = _shader.supportsColorXForm();
			var pma = _shader.hasPMA();
			
			var effect, mvp, crop, alpha;
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
					effect = geometry.effect.__textureEffect;
					
					mvp = renderer.setModelViewProjMatrix(geometry);
					crop = effect.crop;
					alpha = effect.alpha;
					
					//use 3 constant registers (each 4 floats) for mvp matrix, alpha and uv crop (+2 constant registers for color transform)
					offset = (_numSharedRegisters * NUM_FLOATS_PER_REGISTER) + i * (_numRegistersPerQuad * NUM_FLOATS_PER_REGISTER);
					
					constantRegisters[offset +  0] = mvp.m11;
					constantRegisters[offset +  1] = mvp.m12;
					constantRegisters[offset +  2] = 1; //op.zw = 1
					constantRegisters[offset +  3] = mvp.m14;
					
					constantRegisters[offset +  4] = mvp.m21;
					constantRegisters[offset +  5] = mvp.m22;
					constantRegisters[offset +  6] = alpha;
					constantRegisters[offset +  7] = mvp.m24;
					
					constantRegisters[offset +  8] = crop.w * effect.uvScaleX;
					constantRegisters[offset +  9] = crop.h * effect.uvScaleY;
					constantRegisters[offset + 10] = crop.x + effect.uvOffsetX;
					constantRegisters[offset + 11] = crop.y + effect.uvOffsetY;
					
					if (supportsColorXForm)
					{
						var t = effect.colorXForm.multiplier;
						if (pma)
						{
							var am = t.a;
							constantRegisters[offset + 12] = t.r * am * alpha;
							constantRegisters[offset + 13] = t.g * am * alpha;
							constantRegisters[offset + 14] = t.b * am * alpha;
							constantRegisters[offset + 15] = t.a * alpha;
						}
						else
						{
							constantRegisters[offset + 12] = t.r;
							constantRegisters[offset + 13] = t.g;
							constantRegisters[offset + 14] = t.b;
							constantRegisters[offset + 15] = t.a * alpha;
						}
						
						t = effect.colorXForm.offset;
						constantRegisters[offset + 16] = t.r * INV_FF;
						constantRegisters[offset + 17] = t.g * INV_FF;
						constantRegisters[offset + 18] = t.b * INV_FF;
						constantRegisters[offset + 19] = t.a * INV_FF;
					}
				}
				
				_context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, constantRegisters,
					_numSharedRegisters + capacity * _numRegistersPerQuad);
				_context.drawTriangles(_ib.handle, 0, capacity * 2);
				renderer.numCallsToDrawTriangle++;
			}
			
			if (remainder > 0)
			{
				for (i in 0...remainder)
				{
					geometry = batch.get(next++);
					effect = geometry.effect.__textureEffect;
					mvp = renderer.setModelViewProjMatrix(geometry);
					crop = effect.crop;
					offset = (_numSharedRegisters * NUM_FLOATS_PER_REGISTER) + i * (_numRegistersPerQuad * NUM_FLOATS_PER_REGISTER);
					constantRegisters[offset +  0] = mvp.m11;
					constantRegisters[offset +  1] = mvp.m12;
					constantRegisters[offset +  2] = 1;
					constantRegisters[offset +  3] = mvp.m14;
					
					constantRegisters[offset +  4] = mvp.m21;
					constantRegisters[offset +  5] = mvp.m22;
					constantRegisters[offset +  6] = effect.alpha;
					constantRegisters[offset +  7] = mvp.m24;
					
					constantRegisters[offset +  8] = crop.w * effect.uvScaleX;
					constantRegisters[offset +  9] = crop.h * effect.uvScaleY;
					constantRegisters[offset + 10] = crop.x + effect.uvOffsetX;
					constantRegisters[offset + 11] = crop.y + effect.uvOffsetY;
					
					if (supportsColorXForm)
					{
						var t = effect.colorXForm.multiplier;
						constantRegisters[offset + 12] = t.r;
						constantRegisters[offset + 13] = t.g;
						constantRegisters[offset + 14] = t.b;
						constantRegisters[offset + 15] = t.a;
						
						t = effect.colorXForm.offset;
						constantRegisters[offset + 16] = t.r * INV_FF;
						constantRegisters[offset + 17] = t.g * INV_FF;
						constantRegisters[offset + 18] = t.b * INV_FF;
						constantRegisters[offset + 19] = t.a * INV_FF;
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
		
		var uv0 = _uv0;
		var uv1 = _uv1;
		var uv2 = _uv2;
		var uv3 = _uv3;
		var uvs = _uvs;
		var t = _scratchVec3;
		var tv = _scratchVertices;
		var vb = _vb;
		var batch = _batch;
		
		var offset, address, i, size;
		var geometry, effect, world, crop, x, y, w, h, alpha;
		
		var supportsAlpha = _shader.supportsAlpha();
		var supportColorXForm = _shader.supportsColorXForm();
		var pma = _shader.hasPMA();
		
		size = batch.size();
		
		i = 0;
		size = batch.size();
		while (i < size)
		{
			offset = (i << 2) * stride;
			
			geometry = batch.get(i);
			effect = geometry.effect.__textureEffect;
			alpha = effect.alpha;
			
			//update vertices
			world = geometry.world;
			address = offset;
			
			world.applyForwardArr2(geometry.vertices, tv, 4);
			vb.setFloat2(address, tv[0]); address += stride;
			vb.setFloat2(address, tv[1]); address += stride;
			vb.setFloat2(address, tv[2]); address += stride;
			vb.setFloat2(address, tv[3]);
			
			offset += 2;
			
			//update uv
			crop = effect.crop;
			x = crop.x + effect.uvOffsetX;
			y = crop.y + effect.uvOffsetY;
			w = crop.w * effect.uvScaleX;
			h = crop.h * effect.uvScaleY;
			
			uv0.x = x;		//0 * w + x
			uv0.y = y;		//0 * h + y
			uv1.x = w + x;	//1 * w + x
			uv1.y = y;		//0 * h + y
			uv2.x = w + x;	//1 * w + x
			uv2.y = h + y;	//1 * h + y
			uv3.x = x;		//0 * w + x
			uv3.y = h + y;	//1 * h + y
			
			address = offset;
			vb.setFloat2(address, uv0); address += stride;
			vb.setFloat2(address, uv1); address += stride;
			vb.setFloat2(address, uv2); address += stride;
			vb.setFloat2(address, uv3);
			
			offset += 2;
			
			if (supportsAlpha)
			{
				//update alpha
				t.x = alpha;
				address = offset;
				vb.setFloat1(address, t); address += stride;
				vb.setFloat1(address, t); address += stride;
				vb.setFloat1(address, t); address += stride;
				vb.setFloat1(address, t);
				
				offset += 1;
			}
			
			if (supportColorXForm)
			{
				//update color transformation
				t.set(effect.colorXForm.multiplier);
				if (pma)
				{
					var am = t.w;
					t.x *= am * alpha;
					t.y *= am * alpha;
					t.z *= am * alpha;
					t.w *= alpha;
				}
				else
					t.w *= alpha;
				
				var address = offset;
				vb.setFloat4(address, t); address += stride;
				vb.setFloat4(address, t); address += stride;
				vb.setFloat4(address, t); address += stride;
				vb.setFloat4(address, t);
				
				offset += 4;
				
				t.set(effect.colorXForm.offset);
				t.x *= INV_FF;
				t.y *= INV_FF;
				t.z *= INV_FF;
				t.w *= INV_FF;
				address = offset;
				vb.setFloat4(address, t); address += stride;
				vb.setFloat4(address, t); address += stride;
				vb.setFloat4(address, t); address += stride;
				vb.setFloat4(address, t);
				
				offset += 4;
			}
			
			i++;
		}
		
		vb.upload(size << 2);
	}
}