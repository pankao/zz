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
import de.polygonal.ds.TreeNode;
import de.polygonal.ds.Visitable;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.scene.GlobalState.GlobalStateStacks;
import de.polygonal.core.util.Assert;

using de.polygonal.ds.BitFlags;

@:build(de.polygonal.core.util.IntEnum.build(
[
	BIT_LOCAL_CHANGED,
	BIT_WORLD_CHANGED,
	BIT_WORLD_CURRENT,
	BIT_FORCE_CULL,
	BIT_IS_CAMERA,
	BIT_USE_2D_XFORM,
	BIT_MODEL_CHANGED //used in Geometry
], true))
class Spatial implements Visitable
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
	 * Local transformation.
	 */
	public var local(default, null):XForm;
	
	/**
	 * World transformation.
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
	public var anchorX:Float;
	
	/**
	 * Local rotation anchor, y-axis.<br/>
	 * The default value is 0.
	 */
	public var anchorY:Float;
	
	var _bits:Int;
	var _globalStates:GlobalState;
	
	function new(id:String)
	{
		this.id = id;
		treeNode = new TreeNode<Spatial>(this);
		local = new XForm();
		world = new XForm();
		worldBound = new SphereBV();
		effect = null;
		userData = null;
		
		__geometry = null;
		__node = null;
		
		_bits = 0;
		
		x = 0;
		y = 0;
		rotation = 0;
		scaleX = 1;
		scaleY = 1;
		anchorX = 0;
		anchorY = 0;
		
		setf(BIT_LOCAL_CHANGED | BIT_USE_2D_XFORM);
	}
	
	/**
	 * Destroys this object by explicitly nullifying all references for GC'ing used resources.
	 */
	public function free()
	{
		removeAllGlobalStates();
		local.free();
		world.free();
		worldBound.free();
		local = null;
		world = null;
		worldBound = null;
		effect = null;
		userData = null;
		__geometry = null;
		__node = null;
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
	function get_useZ():Bool
	{
		return hasf(BIT_USE_2D_XFORM);
	}
	function set_useZ(value:Bool):Bool
	{
		setfif(BIT_USE_2D_XFORM, value);
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
	
	
	
	
	
	
	
	
	public function visit(preflight:Bool, userData:Dynamic):Bool
	{
		clrf(BIT_WORLD_CHANGED);
		if (effect != null) effect.makeCurrent();
		return true;
	}
	
	/**
	 * TODO
	 */
	public function cull(renderer:Renderer, noCull:Bool):Void
	{
		if (hasf(BIT_FORCE_CULL)) return;
		
		var camera = renderer.camera;
		
		var planeCullState = camera.planeCullState;
		if (noCull || !camera.isCulled(worldBound)) draw(renderer, noCull);
		camera.planeCullState = planeCullState;
	}
	
	public function draw(renderer:Renderer, noCull:Bool):Void {}
	
	public function pick(origin:Vec3, results:Array<Geometry>):Int
	{
		return 0;
	}
	
	/**
	 * Recomputes world transformations and world bounding volumes.
	 * @param intiator if true, the change in world bounding volume occuring at
	 * this node is propagated to the root node.
	 */
	public function updateGeometricState(initiator = true):Void
	{
		//propagate transformations: parent => children
		_updateWorldData();
		
		//propagate world bounding volumes children => parents
		_updateWorldBound(); //implement in subclass
		
		if (initiator) _propagateBoundToRoot();
	}
	
	/**
	 * Updates the world bounding volumes on an upward pass without recomputing transformations.<br/>
	 * Useful if just the model data changes.
	 */
	public function updateBoundState():Void
	{
		_updateWorldBound();
		_propagateBoundToRoot();
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
			_propageStateFromRoot(stacks);
		}
		else
			_pushState(stacks);
		
		//propagate new state to the subtree rooted here
		_propagateRenderStateUpdate(stacks);
		
		initiator ? GlobalState.getStacks() : _popState(stacks);
	}
	
	/**
	 * TODO
	 */
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
	
	/**
	 * TODO
	 */
	public function setGlobalState(state:GlobalState):Void
	{
		#if debug
		D.assert(state != null, 'state != null');
		D.assert(state.next == null, 'state.next == null');
		#end
		
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
			next = node;
		}
		_globalStates = null;
	}
	
	public function toString():String
	{
		if (isGeometry()) return Sprintf.format('Geometry id=%s userData=%s', [id, userData]);
		if (isNode()) return Sprintf.format('Node id=%s userData=%s', [id, userData]);
		return Sprintf.format("? id=%s userData=%s", [id, userData]);
	}
	
	function _updateWorldData():Void
	{
		if (hasf(BIT_WORLD_CURRENT)) return;
		
		var sync = !hasf(BIT_IS_CAMERA);
		if (sync)
		{
			hasf(Spatial.BIT_USE_2D_XFORM) ? _syncLocalXForm2() : _syncLocalXForm();
			clrf(BIT_LOCAL_CHANGED);
			setf(BIT_WORLD_CHANGED);
		}
		
		var parent = treeNode.parent;
		if (parent != null)
		{
			var node:Spatial = parent.val;
			if (sync || node.hasf(BIT_WORLD_CHANGED))
			{
				//W' = Wp * L
				hasf(Spatial.BIT_USE_2D_XFORM) ? world.product2(node.world, local) : world.product(node.world, local);
				setf(BIT_WORLD_CHANGED);
			}
		}
		else
			world.set(local); //root node
	}
	
	function _updateWorldBound():Void {}
	
	function _propagateBoundToRoot():Void
	{
		var parent = treeNode.parent;
		if (parent != null)
		{
			var o = parent.val;
			o._updateWorldBound();
			o._propagateBoundToRoot();
		}
	}
	
	function _propageStateFromRoot(stacks:GlobalStateStacks):Void
	{
		//traverse to root to allow downward state propagation
		var parent = treeNode.parent;
		if (parent != null) parent.val._propageStateFromRoot(stacks);
		_pushState(stacks);
	}
	
	function _propagateRenderStateUpdate(stacks:GlobalStateStacks):Void {}
	
	inline function _syncLocalXForm():Void
	{
		#if debug
		D.assert(!hasf(BIT_IS_CAMERA), '!hasf(BIT_IS_CAMERA)');
		#end
		
		if (rotation != 0)
		{
			var r = local.getRotate();
			r.setRotateZ(rotation);
			
			if (anchorX != 0 || anchorY != 0)
			{
				//1. translate anchor to the origin (-a)
				//2. rotate about the origin
				//3. translate back (+a)
				//var M = new Mat44();
				//M.setScale(sx, sy, 1);
				//M.catTranslate(-ax, -ay, 0);
				//M.catRotateZ(rotation);
				//M.catTranslate(ax + x, ay + y, 0);
				var s = r.sineCosine.x;
				var c = r.sineCosine.y;
				local.setTranslate(x - (c * anchorX - s * anchorY), y - (s * anchorX + c * anchorY), 0);
			}
			else
				local.setTranslate(x - anchorX, y - anchorY, 0);
		}
		else
			local.setTranslate(x - anchorX, y - anchorY, 0);
		
		(scaleX == scaleY) ? local.setUniformScale(scaleX) : local.setScale(scaleX, scaleY, 1);
	}
	
	inline public function _syncLocalXForm2():Void
	{
		#if debug
		D.assert(!hasf(BIT_IS_CAMERA), '!hasf(BIT_IS_CAMERA)');
		#end
		
		if (rotation != 0)
		{
			var r = local.getRotate();
			var sineCosine = TrigApprox.sinCos(rotation, r.sineCosine);
			var s = sineCosine.x;
			var c = sineCosine.y;
			r.m11 = c; r.m12 =-s;
			r.m21 = s; r.m22 = c;
			
			if (anchorX != 0 || anchorY != 0)
				local.setTranslate2(x - (c * anchorX - s * anchorY), y - (s * anchorX + c * anchorY));
			else
				local.setTranslate2(x - anchorX, y - anchorY);
		}
		else
			local.setTranslate2(x - anchorX, y - anchorY);
		
		(scaleX == scaleY) ? local.setUniformScale2(scaleX) : local.setScale2(scaleX, scaleY);
	}
	
	inline function _pushState(stacks:GlobalStateStacks):Void
	{
		var node = _globalStates;
		while (node != null)
		{
			stacks[node.index].push(node);
			node = node.next;
		}
	}
	
	inline function _popState(stacks:GlobalStateStacks):Void
	{
		var node = _globalStates;
		while (node != null)
		{
			stacks[node.index].pop();
			node = node.next;
		}
	}
}