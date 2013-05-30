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
package de.polygonal.zz.scene;

import de.polygonal.core.fmt.Sprintf;
import de.polygonal.core.math.Mathematics;
import de.polygonal.core.math.TrigApprox;
import de.polygonal.core.math.Vec3;
import de.polygonal.ds.Bits;
import de.polygonal.ds.HashableItem;
import de.polygonal.ds.TreeNode;
import de.polygonal.ds.Visitable;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.scene.GlobalState.GlobalStateStacks;
import de.polygonal.core.util.Assert;

using de.polygonal.ds.BitFlags;

@:build(de.polygonal.core.util.IntEnum.build(
[
	BIT_UPDATE_WORLD_XFORM,
	BIT_FORCE_CULL,
	BIT_USE_3D_XFORM,
	BIT_HAS_ROTATION,
	BIT_MODEL_CHANGED,
	BIT_UPDATE_WORLD_BOUND
], true))
class Spatial extends HashableItem
{
	/**
	 * The id of this object.<br/>
	 * Default is null.
	 */
	public var id:String;
	
	/**
	 * Custom application data.<br/>
	 * Default is null.
	 */
	public var userData:Dynamic;
	
	/**
	 * Local transformation (relative to parent node).
	 */
	public var local(default, null):XForm;
	
	/**
	 * World transformation (relative to root node).
	 */
	public var world(default, null):XForm;
	
	/**
	 * World bounding volume.
	 */
	public var worldBound(default, null):BoundingVolume;
	
	/**
	 * Defines the visual appearance of this node.
	 */
	public var effect:Effect;
	
	/**
	 * A pointer to the <em>TreeNode</em> object storing this node.
	 */
	public var treeNode(default, null):TreeNode<Spatial>;
	
	/**
	 * Non-null if this object is of type <em>Geometry</em>.<br/>
	 * Useful to avoid slow downcasts.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var geometry = myNode.getChildAt(0).__geometry;</pre>
	 */
	public var __geometry(default, null):Geometry;
	
	/**
	 * Non-null if this object is of type <em>Node</em>.<br/>
	 * Useful to avoid slow downcasts.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var node = myNode.getChildAt(0).__node;</pre>
	 */
	public var __node(default, null):Node;
	
	/**
	 * Local translation, x-axis.<br/>
	 * The default value is 0.
	 */
	public var x:Float;
	
	/**
	 * Local translation, y-axis.<br/>
	 * The default value is 0.
	 */
	public var y:Float;
	
	/**
	 * Local rotation angle in radians.<br/>
	 * The default value is 0.
	 */
	public var rotation:Float;
	
	/**
	 * Local scale, x-axis.<br/>
	 * The default value is 1.
	 */
	public var scaleX:Float;
	
	/**
	 * Local scale, y-axis.<br/>
	 * The default value is 1.
	 */
	public var scaleY:Float;
	
	/**
	 * Local rotation anchor, x-axis.<br/>
	 * The default value is 0.
	 */
	public var centerX:Float;
	
	/**
	 * Local rotation anchor, y-axis.<br/>
	 * The default value is 0.
	 */
	public var centerY:Float;
	
	/**
	 * Uniform scale.
	 */
	public var scale(get_scale, set_scale):Float;
	inline function get_scale():Float
	{
		D.assert(scaleX == scaleY, 'non-uniform scale');
		return scaleX;
	}
	inline function set_scale(value:Float):Float
	{
		scaleX = scaleY = value;
		return value;
	}
	
	public var __next:Spatial;
	
	var _bits:Int;
	var _globalStates:GlobalState;
	
	function new(id:String)
	{
		super();

		this.id = id;
		treeNode = new TreeNode<Spatial>(this);
		local = new XForm();
		world = new XForm();
		worldBound = new SphereBV();
		effect = null;
		userData = null;
		
		__geometry = null;
		__node = null;
		
		_bits = BIT_UPDATE_WORLD_XFORM | BIT_UPDATE_WORLD_BOUND;
		
		x = 0;
		y = 0;
		rotation = 0;
		scaleX = 1;
		scaleY = 1;
		centerX = 0;
		centerY = 0;
	}
	
	/**
	 * Destroys this object by explicitly nullifying all references for GC'ing used resources.
	 */
	public function free():Void
	{
		if (treeNode == null) return;
		
		treeNode.unlink();
		treeNode.free();
		treeNode = null;
		
		removeAllGlobalStates();
		local.free();
		local = null;
		
		world.free();
		world = null;
		
		worldBound.free();
		worldBound = null;
		
		effect = null;
		userData = null;
		
		__geometry = null;
		__node = null;
		__next = null;
	}
	
	/**
	 * Returns true if this object is of type <em>Node</em>.
	 */
	inline public function isNode():Bool
	{
		return __node != null;
	}
	
	/**
	 * Returns true if this object is of type <em>Geometry</em>.
	 */
	inline public function isGeometry():Bool
	{
		return __geometry != null;
	}
	
	/**
	 * Returns the parent node or null if this node is a root node.
	 */
	inline public function getParent():Node
	{
		return treeNode.hasParent() ? treeNode.parent.val.__node : null;
	}
	
	/**
	 * Removes this node from the scene graph and returns its parent.
	 */
	public function remove():Node
	{
		var parent = treeNode.parent;
		if (parent != null)
		{
			treeNode.unlink();
			return parent.val.__node;
		}
		return null;
	}
	
	/**
	 * Sets the rotation angle to <code>deg</code> in degrees.
	 */
	inline public function setAngle(deg:Float):Void
	{
		rotation = M.wrapToPI(deg * M.DEG_RAD);
	}
	
	/**
	 * If false, ignores the z-component to speed up computations.
	 */
	public var useZ(get_useZ, set_useZ):Bool;
	inline function get_useZ():Bool
	{
		return hasf(BIT_USE_3D_XFORM);
	}
	inline function set_useZ(value:Bool):Bool
	{
		setfif(BIT_USE_3D_XFORM, value);
		return value;
	}
	
	public var forceCull(get_forceCull, set_forceCull):Bool;
	inline function get_forceCull():Bool
	{
		return hasf(BIT_FORCE_CULL);
	}
	inline function set_forceCull(value:Bool):Bool
	{
		setfif(BIT_FORCE_CULL, value);
		return value;
	}
	
	public function cull(renderer:Renderer, noCull:Bool):Void
	{
		if (hasf(BIT_FORCE_CULL)) return;
		
		var camera = renderer.getCamera();
		
		var planeCullState = camera.planeCullState;
		if (noCull || !camera.isCulled(worldBound)) draw(renderer, noCull);
		camera.planeCullState = planeCullState;
	}
	
	public function draw(renderer:Renderer, noCull:Bool):Void {}
	
	public function pick(origin:Vec3, result:PickResult):Int
	{
		return 0;
	}
	
	/**
	 * Recomputes world transformations and world bounding volumes.
	 * @param intiator if true, the change in world bounding volume occuring at
	 * this node is propagated to the root node.
	 * @param updateBV if false, skips recomputing bounding volumes.
	 */
	public function updateGeometricState(initiator = true, updateBV = true):Void
	{
		//propagate transformations: parent => children
		updateWorldData(updateBV);
		
		//propagate world bounding volumes: children => parents
		if (updateBV) updateWorldBound(); //hook; implement in subclass
		
		if (initiator && updateBV) propagateBoundToRoot();
	}
	
	/**
	 * Updates the world bounding volumes on an upward pass without recomputing transformations.<br/>
	 * Useful if just the model data changes.
	 */
	public function updateBoundState(propagateToRoot = true):Void
	{
		updateWorldBound();
		if (propagateToRoot) propagateBoundToRoot();
	}
	
	/**
	 * Assembles the rendering information at this node by traversing the scene graph hierarchy.
	 */
	public function updateRenderState(stacks:GlobalStateStacks = null):Void
	{
		var initiator = stacks == null;
		
		if (initiator)
		{
			stacks = GlobalState.getStacks();
			
			//traverse to root and push states from root to this node
			propageStateFromRoot(stacks);
		}
		else
			pushState(stacks);
		
		//propagate new state to the subtree rooted here
		propagateRenderStateUpdate(stacks);
		
		initiator ? GlobalState.clrStacks() : popState(stacks);
	}
	
	public function getGlobalState(type:GlobalStateType):GlobalState
	{
		var node = _globalStates;
		while (node != null)
		{
			if (node.type == type) return node;
			node = node.next;
		}
		return null;
	}
	
	public function setGlobalState(state:GlobalState):Void
	{
		D.assert(state != null, 'state != null');
		D.assert(state.next == null, 'state.next == null');
		
		//set initial state
		if (_globalStates == null)
		{
			_globalStates = state;
			return;
		}
		
		//replace existing state
		var node = _globalStates, prev = null, type = state.type;
		while (node != null)
		{
			if (node.type == type)
			{
				state.next = node.next;
				if (prev != null)
					prev.next = state;
				else
					_globalStates = state;
				node.next = null;
				return;
			}
			prev = node;
			node = node.next;
		}
		
		//add state
		state.next = _globalStates;
		_globalStates = state;
	}
	
	public function removeGlobalState(type:GlobalStateType):Void
	{
		var node = _globalStates, prev = null;
		while (node != null)
		{
			if (node.type == type)
			{
				if (prev != null)
					prev.next = node.next;
				else
					_globalStates = node.next;
				return;
			}
			prev = node;
			node = node.next;
		}
	}
	
	public function removeAllGlobalStates():Void
	{
		var node = _globalStates, next;
		while (node != null)
		{
			next = node.next;
			node.next = null;
			node = next;
		}
		_globalStates = null;
	}
	
	public function toString():String
	{
		if (isGeometry()) return Sprintf.format('Geometry id=%s userData=%s', [id, userData]);
		if (isNode()) return Sprintf.format('Node id=%s userData=%s', [id, userData]);
		return Sprintf.format("? id=%s userData=%s", [id, userData]);
	}
	
	function updateWorldData(updateBV:Bool):Void
	{
		if (!hasf(BIT_UPDATE_WORLD_XFORM)) return;
		
		useZ ? syncLocalXForm3d() : syncLocalXForm2d();
		
		var parent = treeNode.parent;
		if (parent != null)
		{
			//W' = Wp * L
			useZ ? world.product(parent.val.world, local) : world.product2(parent.val.world, local);
		}
		else
			world.set(local); //root node
	}
	
	function updateWorldBound():Void
	{
	}
	
	function propagateBoundToRoot():Void
	{
		var parent = treeNode.parent;
		if (parent != null)
		{
			var o = parent.val;
			o.updateWorldBound();
			o.propagateBoundToRoot();
		}
	}
	
	function propageStateFromRoot(stacks:GlobalStateStacks):Void
	{
		//traverse to root to allow downward state propagation
		var parent = treeNode.parent;
		if (parent != null) parent.val.propageStateFromRoot(stacks);
		pushState(stacks);
	}
	
	function propagateRenderStateUpdate(stacks:GlobalStateStacks):Void
	{
	}
	
	function syncLocalXForm2d():Void
	{
		var cx = centerX * M.fsgn(scaleX);
		var cy = centerY * M.fsgn(scaleY);
		
		if (rotation != 0)
		{
			setf(BIT_HAS_ROTATION);
			var r = local.getRotate();
			var sineCosine = TrigApprox.sinCos(rotation, r.sineCosine);
			var s = sineCosine.x;
			var c = sineCosine.y;
			r.m11 = c; r.m12 =-s;
			r.m21 = s; r.m22 = c;
			local.setTranslate2(x - (c * cx - s * cy), y - (s * cx + c * cy));
		}
		else
		{
			if (hasf(BIT_HAS_ROTATION))
			{
				//rotation was set to zero so reset rotation matrix
				clrf(BIT_HAS_ROTATION);
				var r = local.getRotate();
				r.m11 = 1; r.m12 = 0;
				r.m21 = 0; r.m22 = 1;
			}
			
			local.setTranslate2(x - cx, y - cy);
		}
		
		(scaleX == scaleY) ? local.setUniformScale2(scaleX) : local.setScale2(scaleX, scaleY);
	}
	
	function syncLocalXForm3d():Void
	{
		if (rotation != 0)
		{
			setf(BIT_HAS_ROTATION);
			var r = local.getRotate();
			r.setRotateZ(rotation);
			
			if (centerX != 0 || centerY != 0)
			{
				//1. translate anchor to the origin (-a)
				//2. rotate about the origin
				//3. translate back (+a)
				//var M = new Mat44();
				//M.setScale(sx, sy, 1);
				//M.catTranslate(-cx, -cy, 0);
				//M.catRotateZ(rotation);
				//M.catTranslate(cx + x, cy + y, 0);
				var s = r.sineCosine.x;
				var c = r.sineCosine.y;
				local.setTranslate(x - (c * centerX - s * centerY), y - (s * centerX + c * centerY), 0);
			}
			else
				local.setTranslate(x - centerX, y - centerY, 0);
		}
		else
		{
			if (hasf(BIT_HAS_ROTATION))
			{
				clrf(BIT_HAS_ROTATION);
				local.getRotate().setIdentity();
			}
			local.setTranslate(x - centerX, y - centerY, 0);
		}
		
		(scaleX == scaleY) ? local.setUniformScale(scaleX) : local.setScale(scaleX, scaleY, 1);
	}
	
	inline function pushState(stacks:GlobalStateStacks):Void
	{
		var node = _globalStates;
		while (node != null)
		{
			stacks[node.index].push(node);
			node = node.next;
		}
	}
	
	inline function popState(stacks:GlobalStateStacks):Void
	{
		var node = _globalStates;
		while (node != null)
		{
			stacks[node.index].pop();
			node = node.next;
		}
	}
}