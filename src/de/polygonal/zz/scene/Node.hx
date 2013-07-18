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
import de.polygonal.motor.geom.primitive.Sphere2;
import de.polygonal.core.util.Assert;
import de.polygonal.zz.scene.GlobalState.GlobalStateStacks;

using de.polygonal.ds.BitFlags;

/**
 * responsibility: grouping and child pointers
 */
class Node extends Spatial
{
	public function new(id:String = null)
	{
		super(id);
		__node = this;
	}
	
	/**
	 * Adds a <code>child</code> node to the end of the list of children of this node.
	 */
	public function addChild(child:Spatial):Void
	{
		D.assert(child != null, 'child is null');
		D.assert(!treeNode.contains(child), 'child was added before');
		treeNode.appendNode(child.treeNode);
	}
	
	/**
	 * Removes a <code>child</code> node from the list of children of this node.
	 */
	public function removeChild(child:Spatial):Void
	{
		D.assert(child != null, 'child != null');
		D.assert(child.treeNode != null, 'child has been freed');
		child.treeNode.unlink();
	}
	
	public function addChildAt(child:Spatial, index:Int):Void
	{
		D.assert(child != null, 'child != null');
		treeNode.insertChildAt(child.treeNode, index);
	}
	
	public function removeChildAt(index:Int):Spatial
	{
		return treeNode.removeChildAt(index).val;
	}
	
	public function removeChildren(beginIndex = 0, count = -1):Void
	{
		treeNode.removeChildren(beginIndex, count);
	}
	
	public function getChildAt(index:Int):Spatial
	{
		return treeNode.getChildAt(index).val;
	}
	
	public function getChildIndex(child:Spatial):Int
	{
		D.assert(child != null, 'child != null');
		return child.treeNode.getChildIndex();
	}
	
	public function setChildIndex(child:Spatial, index:Int):Void
	{
		D.assert(child != null, 'child != null');
		treeNode.setChildIndex(child.treeNode, index);
	}
	
	public function getChildById(id:String):Spatial
	{
		var n = treeNode.children;
		while (n != null)
		{
			if (n.val.id == id)
				return n.val;
			n = n.next;
		}
		return null;
	}
	
	public function swapChildren(child1:Spatial, child2:Spatial):Void
	{
		D.assert(child1 != null, 'child1 != null');
		D.assert(child2 != null, 'child2 != null');
		treeNode.swapChildren(child1.treeNode, child2.treeNode);
	}
	
	public function swapChildrenAt(index1:Int, index2:Int):Void
	{
		treeNode.swapChildrenAt(index1, index2);
	}
	
	/**
	 * If <code>x</code> is false, world bound computations are ignored, that is calling <em>updateWorldBound()</em> has no effect.
	 */
	public function enableUpdateBV(x:Bool):Void
	{
		setfif(Spatial.BIT_UPDATE_WORLD_BOUND, x);
	}
	
	/**
	 * Draws this scene using the given <code>renderer</code> object.
	 * @param noCull if true, skips culling.
	 */
	override public function draw(renderer:Renderer, noCull:Bool):Void
	{
		if (effect == null)
		{
			//no effect assign, so just draw children.
			var n = treeNode.children;
			while (n != null)
			{
				n.val.cull(renderer, noCull);
				n = n.next;
			}
		}
		else
			renderer.drawNode(this);
	}
	
	override public function pick(origin:Vec3, result:PickResult):Int
	{
		var c = 0;
		if (!hasf(Spatial.BIT_UPDATE_WORLD_BOUND) || worldBound.contains(origin))
		{
			var n = treeNode.children;
			while (n != null)
			{
				c += n.val.pick(origin, result);
				n = n.next;
			}
		}
		return c;
	}
	
	override function propagateRenderStateUpdate(stack:GlobalStateStacks):Void
	{
		//downward pass: propagate render state to children
		var n = treeNode.children;
		while (n != null)
		{
			n.val.updateRenderState(stack);
			n = n.next;
		}
	}
	
	override function updateWorldData(updateBV:Bool):Void
	{
		super.updateWorldData(updateBV);
		
		//downward pass: propagate geometric update to children
		var n = treeNode.children;
		while (n != null)
		{
			n.val.updateGeometricState(false, updateBV);
			n = n.next;
		}
	}
	
	override function updateWorldBound():Void
	{
		if (!hasf(Spatial.BIT_UPDATE_WORLD_BOUND)) return;
		
		//compute world bounding volume containing world bounding volume of all its children
		//set to first non-null child
		var n = treeNode.children;
		if (n != null)
			worldBound.set(n.val.worldBound);
		else
			return; //no children
		
		//merge current world bound with child world bound
		n = n.next;
		while (n != null)
		{
			worldBound.growToContain(n.val.worldBound);
			n = n.next;
		}
	}
}