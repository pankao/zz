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
 * Copyright (c) 2012 Michael Baczynski, http://www.polygonal.de
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
package de.polygonal.zz.scene;

import de.polygonal.core.math.Vec3;
import de.polygonal.ds.Bits;
import de.polygonal.ds.DA;
import de.polygonal.zz.scene.GlobalState.GlobalStateStacks;

using de.polygonal.ds.BitFlags;

class VertexFormat
{
	inline public static var FLOAT2 = 1;
	inline public static var FLOAT3 = 2;
}

/**
 * Responsibility: model data, container for vertices/normals/indices.
 */
class Geometry extends Spatial
{
	public var type(default, null):Int;
	
	public var vertexFormat:Int;
	
	public var cached:Bool;
	
	public var vertices:Array<Vec3>;
	public var indices:Array<Int>;
	public var normals:Array<Vec3>;
	
	public var modelBound:BoundingVolume;
	
	public var states:DA<GlobalState>;
	public var stateFlags:Int;
	
	function new(geometryType:Int, id:String = null)
	{
		super(id);
		__geometry = this;
		
		type = geometryType;
		
		vertexFormat = 0;
		vertices = new Array<Vec3>();
		indices = new Array<Int>();
		modelBound = new SphereBV();
		
		states = null;
	}
	
	override public function free()
	{
		super.free();
		modelBound.free();
		modelBound = null;
		
		vertices = null;
		indices = null;
		normals = null;

		if (states != null)
		{
			states.free();
			states = null;
		}
	}
	
	inline public function hasModelChanged():Bool
	{
		return hasf(Spatial.BIT_MODEL_CHANGED);
	}
	
	override public function draw(renderer:Renderer, noCull:Bool):Void
	{
		renderer.drawGeometry(this);
		renderer.numCallsToDrawGeometry++;
	}
	
	public function updateModelState():Void
	{
		useZ ? syncLocalXForm3d() : syncLocalXForm2d();
		updateModelBound();
		setf(Spatial.BIT_MODEL_CHANGED);
	}
	
	override function updateWorldBound():Void
	{
		//apply current world transformation to compute world bounding volume from model bounding volume
		modelBound.transformBy(world, worldBound);
	}
	
	override function propagateRenderStateUpdate(stacks:GlobalStateStacks)
	{
		//render state at leaf node represents all global states from root to leaf
		//make local copy of the stack contents
		if (states == null)
		{
			var max = Type.getEnumConstructs(GlobalStateType).length;
			states = new DA<GlobalState>(max, max);
			states.fill(null, max);
		}
		
		stateFlags = 0;
		for (i in 0...stacks.length)
		{
			var stack = stacks[i];
			if (!stack.isEmpty())
			{
				var state = stack.top();
				states.set(i, state);
				stateFlags |= state.flags;
			}
		}
	}
	
	function updateModelBound():Void
	{
		//compute model bounding volume from vertices
		modelBound.computeFromData(vertices);
	}
}