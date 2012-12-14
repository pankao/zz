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
import de.polygonal.core.util.ClassUtil;
import de.polygonal.ds.ArrayUtil;
import de.polygonal.ds.BitVector;
import de.polygonal.ds.DA;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.flash.stage3d.shader.AGALShader;
import de.polygonal.zz.render.flash.stage3d.Stage3DTextureFlag;
import de.polygonal.zz.render.module.FlashStage3DRenderer;
import de.polygonal.zz.scene.Geometry;
import de.polygonal.zz.scene.GeometryType;
import de.polygonal.zz.scene.TriMesh;
import flash.display3D.Context3D;
import flash.Vector;

class Stage3DBrush
{
	var _context:Context3D;
	var _vb:Stage3DVertexBuffer;
	var _ib:Stage3DIndexBuffer;
	var _shader:AGALShader;
	
	var _batch:DA<Geometry>;
	var _batchCapacity:Int;
	var _scratchVector:Vector<Float>;
	var _scratchVec3:Vec3;
	
	public function new(context:Context3D, effectFlags:Int, textureFlags:Int)
	{
		_context = context;
		
		_batch = new DA();
		_batchCapacity = -1;
		_scratchVector = new flash.Vector<Float>();
		_scratchVec3 = new Vec3();
		
		trace('create brush: %-30s effects: %-30s texture flags: %s', ClassUtil.getUnqualifiedClassName(Type.getClass(this)),
			Effect.print(effectFlags), 
			Stage3DTextureFlag.print(textureFlags));
	}
	
	public function free():Void
	{
		if (_vb != null) _vb.free();
		if (_ib != null) _ib.free();
		
		_batch.clear(true);
		_batch = null;
		
		_shader.free();
	}
	
	public function bindVertexBuffer():Void
	{
		_vb.bind();
	}
	
	inline public function unbindVertexBuffer():Void
	{
		_vb.unbind();
	}
	
	inline public function add(x:Geometry):Void
	{
		_batch.pushBack(x);
	}
	
	inline public function isFull():Bool
	{
		return _batch.size() == _batchCapacity;
	}
	
	inline public function isEmpty():Bool
	{
		return _batch.isEmpty();
	}
	
	public function draw(renderer:FlashStage3DRenderer):Void
	{
		_batch.clear();
	}
	
	//TODO add UVs and indices
	function fillBuffer(geometry:Geometry)
	{
		_vb = new Stage3DVertexBuffer(_context);
		
		throw 'untested';
		
		//TODO allow customization customize
		_vb.allocate([2], 1000);
		
		_ib = new Stage3DIndexBuffer(_context);
		
		var indices = geometry.indices;
		var vertices = geometry.vertices;
		
		if (geometry.type == GeometryType.QUAD)
		{
			for (i in 0...4) _vb.addFloat2(vertices[i]);
			for (i in 0...6) _ib.add(indices[i]);
		}
		else
		if (geometry.type == GeometryType.TRIMESH)
		{
			var mesh:TriMesh = cast geometry;
			
			var numTriangles = mesh.getNumTriangles();
			
			var added = new BitVector(numTriangles * 3);
			
			var indexLUT = ArrayUtil.alloc(1024);
			
			var nextIndex = 0;
			
			for (i in 0...numTriangles)
			{
				var triOffset = i * 3;
				for (j in 0...3)
				{
					var index = indices[triOffset + j];
					
					if (added.has(index))
						_ib.add(indexLUT[index]);
					else
					{
						added.set(index);
						indexLUT[index] = nextIndex;
						nextIndex++;
						
						if (geometry.vertexFormat == VertexFormat.FLOAT2)
							_vb.addFloat2(vertices[index]);
						else
							_vb.addFloat3(vertices[index]);
						
						_ib.add(nextIndex);
					}
				}
			}
			
			added.free();
			
			//general version using getTriangle(i);
			/*var tri = geometry.getTriangle(i);
			 * 
			for (j in 0...3)
			{
				var index = tri.indices[j];
				
				if (added.has(index))
					_ib.add(indexLUT[index]);
				else
				{
					_vb.add(VertexAttribute.POSITION2, tri.vertices[index]);
					_ib.add(nextIndex);
					added.set(index);
					indexLUT[index] = nextIndex++;
				}
			}*/
			
			/*if (added.has(tri.i0))
				_ib.add(indexLUT[tri.i0]);
			else
			{
				_vb.add(VertexAttribute.POSITION2, tri.v0);
				_ib.add(nextIndex);
				added.set(tri.i0);
				indexLUT[tri.i0] = nextIndex++;
			}
			
			if (added.has(tri.i1))
				_ib.add(indexLUT[tri.i1]);
			else
			{
				_vb.add(VertexAttribute.POSITION2, tri.v1);
				_ib.add(nextIndex);
				added.set(tri.i1);
				indexLUT[tri.i1] = nextIndex++;
			}
			
			if (added.has(tri.i2))
				_ib.add(indexLUT[tri.i2]);
			else
			{
				_vb.add(VertexAttribute.POSITION2, tri.v2);
				_ib.add(nextIndex);
				added.set(tri.i2);
				indexLUT[tri.i2] = nextIndex++;
			}*/
		}
	}
}