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

import de.polygonal.core.math.Vec3;
import de.polygonal.ds.DA;
import de.polygonal.zz.render.flash.stage3d.shader.AGALTextureBatchConstantShader;
import de.polygonal.zz.render.flash.stage3d.shader.AGALTextureBatchVertexShader;
import de.polygonal.zz.render.module.FlashStage3DRenderer;
import de.polygonal.zz.scene.Geometry;
import de.polygonal.zz.scene.Spatial;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;

using de.polygonal.ds.BitFlags;

class Stage3DBrushRectTextureBatch extends Stage3DBrushRect
{
	inline static var INV_FF = .00392156;
	inline static var MAX_SUPPORTED_REGISTERS = 128;
	inline static var NUM_FLOATS_PER_REGISTER = 4;
	
	public static var MAX_BATCH_SIZE_QUADS = 4096;
	
	var _numSharedRegisters:Int;
	var _numRegistersPerQuad:Int;
	var _strategy:Int;
	
	var _uv0:Vec3;
	var _uv1:Vec3;
	var _uv2:Vec3;
	var _uv3:Vec3;
	var _uvs:Array<Vec3>;
	
	var _bindVertexBuffer:Bool;
	
	public function new(context:Context3D, effectMask:Int, textureFlags:Int)
	{
		super(context, effectMask, textureFlags);
		
		_strategy = FlashStage3DRenderer.BATCH_STRATEGY;
		
		_batchCapacity = MAX_BATCH_SIZE_QUADS;
		
		_uv0 = new Vec3();
		_uv1 = new Vec3();
		_uv2 = new Vec3();
		_uv3 = new Vec3();
		_uvs = [_uv0, _uv1, _uv2, _uv3];
		
		if (_strategy == 0)
		{
			_shader = Type.createInstance(AGALTextureBatchVertexShader, [_context, effectMask, textureFlags]);
			
			var numFloatsPerAttribute = [2, 2];
			
			if (_shader.supportsAlpha()) numFloatsPerAttribute.push(1);
			if (_shader.supportsColorXForm())
			{
				numFloatsPerAttribute.push(4);
				numFloatsPerAttribute.push(4);
			}
			
			_vb = new Stage3DVertexBuffer(_context);
			_vb.allocate(numFloatsPerAttribute, _batchCapacity * 4);
		}
		else
		if (_strategy == 1)
		{
			_shader = Type.createInstance(AGALTextureBatchConstantShader, [_context, effectMask, textureFlags]);
			
			_numSharedRegisters = 0;
			_numRegistersPerQuad = _shader.supportsColorXForm() ? 5 : 3;
			
			_scratchVector.length = MAX_SUPPORTED_REGISTERS * NUM_FLOATS_PER_REGISTER;
			_scratchVector.fixed = true;
			
			var maxBatchSize = Std.int((MAX_SUPPORTED_REGISTERS - _numSharedRegisters) / _numRegistersPerQuad);
			if (_batchCapacity > maxBatchSize) _batchCapacity = maxBatchSize;
			
			_vb = new Stage3DVertexBuffer(_context);
			_vb.allocate(_shader.supportsColorXForm() ? [2, 3, 2] : [2, 3], maxBatchSize * 4);
			
			var vertices = [new Vec3(0, 0), new Vec3(1, 0), new Vec3(1, 1), new Vec3(0, 1)];
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
						_vb.addFloat2(vertices[i]);
						_vb.addFloat3(address3);
						_vb.addFloat2(address2);
					}
				}
				else
				{
					for (i in 0...4)
					{
						_vb.addFloat2(vertices[i]);
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
	
	override public function bindVertexBuffer():Void
	{
		_bindVertexBuffer = true;
	}
	
	override public function draw(renderer:FlashStage3DRenderer):Void
	{
		var constantRegisters = _scratchVector;
		
		if (_strategy == 0) //"vertex batching"
		{
			updateVertexBuffer();
			
			var vp = renderer.currViewProjMatrix;
			vp.m13 = 1; //op.zw
			vp.toVector(constantRegisters);
			
			_context.setProgramConstantsFromVector(flash.display3D.Context3DProgramType.VERTEX, 0, constantRegisters, 2);
			
			_shader.bindProgram();
			
			_shader.bindTexture(0, renderer.currStage3DTexture.handle);
			
			if (_bindVertexBuffer) _vb.bind();
			
			_context.drawTriangles(_ib.handle, 0, _batch.size() << 1);
			renderer.numCallsToDrawTriangle++;
			
			_batch.clear();
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
			
			var supportsColorXForm = _shader.supportsColorXForm();
			
			var texture = renderer.currTexture;
			_shader.bindTexture(0, renderer.currStage3DTexture.handle);
			_shader.bindProgram();
			
			if (_bindVertexBuffer) _vb.bind();
			
			var geometry, effect, mvp, crop;
			var offset;
			var capacity = _batchCapacity;
			var fullPasses = Std.int(size / capacity);
			var remainder = size % capacity;
			var next = 0;
			for (pass in 0...fullPasses)
			{
				for (i in 0...capacity)
				{
					geometry = batch.get(next++);
					effect = geometry.effect;
					
					mvp = renderer.setModelViewProjMatrix(geometry);
					crop = effect.__textureEffect.crop;
					
					//use 3 constant register (each 4 floats) for mvp matrix, alpha and uv crop (+2 constant registers for color transform)
					offset = (_numSharedRegisters * NUM_FLOATS_PER_REGISTER) + i * (_numRegistersPerQuad * NUM_FLOATS_PER_REGISTER);
					
					constantRegisters[offset +  0] = mvp.m11;
					constantRegisters[offset +  1] = mvp.m12;
					constantRegisters[offset +  2] = 1; //op.zw = 1
					constantRegisters[offset +  3] = mvp.m14;
					
					constantRegisters[offset +  4] = mvp.m21;
					constantRegisters[offset +  5] = mvp.m22;
					constantRegisters[offset +  6] = geometry.effect.alpha;
					constantRegisters[offset +  7] = mvp.m24;
					
					constantRegisters[offset +  8] = crop.w;
					constantRegisters[offset +  9] = crop.h;
					constantRegisters[offset + 10] = crop.x;
					constantRegisters[offset + 11] = crop.y;
					
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
					_numSharedRegisters + capacity * _numRegistersPerQuad);
				_context.drawTriangles(_ib.handle, 0, capacity * 2);
				renderer.numCallsToDrawTriangle++;
			}
			
			if (remainder > 0)
			{
				for (i in 0...remainder)
				{
					geometry = batch.get(next++);
					effect = geometry.effect;
					mvp = renderer.setModelViewProjMatrix(geometry);
					crop = effect.__textureEffect.crop;
					offset = (_numSharedRegisters * NUM_FLOATS_PER_REGISTER) + i * (_numRegistersPerQuad * NUM_FLOATS_PER_REGISTER);
					constantRegisters[offset +  0] = mvp.m11;
					constantRegisters[offset +  1] = mvp.m12;
					constantRegisters[offset +  2] = 1;
					constantRegisters[offset +  3] = mvp.m14;
					
					constantRegisters[offset +  4] = mvp.m21;
					constantRegisters[offset +  5] = mvp.m22;
					constantRegisters[offset +  6] = geometry.effect.alpha;
					constantRegisters[offset +  7] = mvp.m24;
					
					constantRegisters[offset +  8] = crop.w;
					constantRegisters[offset +  9] = crop.h;
					constantRegisters[offset + 10] = crop.x;
					constantRegisters[offset + 11] = crop.y;
					
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
			
			_batch.clear();
		}
		
		super.draw(renderer);
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
		var vb = _vb;
		var batch = _batch;
		
		var offset, address, i, size;
		var geometry, effect, vertices, world, crop, x, y, w, h;
		
		var supportsAlpha = _shader.supportsAlpha();
		var supportColorXForm = _shader.supportsColorXForm();
		
		size = batch.size();
		
		i = 0;
		size = batch.size();
		while (i < size)
		{
			offset = (i << 2) * stride;
			
			geometry = batch.get(i);
			effect = geometry.effect.__textureEffect;
			
			//update vertices
			vertices = geometry.vertices;
			world = geometry.world;
			address = offset;
			vb.setFloat2(address, world.applyForward2(vertices[0], t)); address += stride;
			vb.setFloat2(address, world.applyForward2(vertices[1], t)); address += stride;
			vb.setFloat2(address, world.applyForward2(vertices[2], t)); address += stride;
			vb.setFloat2(address, world.applyForward2(vertices[3], t));
			
			offset += 2;
			
			//update uv
			crop = effect.crop;
			x = crop.x;
			y = crop.y;
			w = crop.w;
			h = crop.h;
			
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
				t.x = effect.alpha;
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
				t = effect.colorXForm.multiplier;
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