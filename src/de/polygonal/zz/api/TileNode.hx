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
package de.polygonal.zz.api;
 
import de.polygonal.core.math.Mathematics;
import de.polygonal.ds.TreeNode;
import de.polygonal.zz.scene.Node;
import de.polygonal.zz.scene.Spatial;
import de.polygonal.core.util.Assert;

/**
 * A TileNode object wraps a <em>Node</em> node to provide a simple interface.
 */
@:access(de.polygonal.zz.api.Tile)
class TileNode extends AbstractTile
{
	public function new(id:String = null)
	{
		super();
		
		sgn = new Node(id);
		TileManager.register(this, sgn);
	}
	
	override public function free():Void
	{
		if (sgn == null) return;
		
		TileManager.unregister(sgn);
		sgn.free();
		sgn = null;
	}
	
	public var id(get_id, set_id):String;
	inline function get_id():String return sgn.id;
	inline function set_id(value:String):String return sgn.id = value;
	
	/**
	 * The x coordinate relative to the local coordinates of the parent object.
	 */
	public var x(get_x, set_x):Float;
	inline function get_x():Float return sgn.x;
	inline function set_x(value:Float):Float return sgn.x = value;
	
	/**
	 * The y coordinate relative to the local coordinates of the parent object.
	 */
	public var y(get_y, set_y):Float;
	inline function get_y():Float return sgn.y;
	inline function set_y(value:Float):Float return sgn.y = value;
	
	/**
	 * The rotation in degrees relative to the local coordinates of the parent object.<br/>
	 * Positive rotation is CW.
	 */
	public var rotation(get_rotation, set_rotation):Float;
	inline function get_rotation():Float return M.RAD_DEG * sgn.rotation;
	inline function set_rotation(angle:Float):Float
	{
		sgn.rotation = M.DEG_RAD * angle;
		return angle;
	}
	
	public var scaleX(get_scaleX, set_scaleX):Float;
	inline function get_scaleX():Float return sgn.scaleX;
	inline function set_scaleX(value:Float):Float
	{
		sgn.scaleX = value;
		return value;
	}
	
	/**
	 * The vertical scale of the object relative to the center point.
	 */
	public var scaleY(get_scaleY, set_scaleY):Float;
	inline function get_scaleY():Float return sgn.scaleX;
	inline function set_scaleY(value:Float):Float
	{
		sgn.scaleY = value;
		return value;
	}
	
	public var scale(get_scale, set_scale):Float;
	inline function get_scale():Float
	{
		D.assert(sgn.scaleX == sgn.scaleY, 'scaleX != scaleY');
		return sgn.scaleX;
	}
	inline function set_scale(value:Float):Float
	{
		scaleX = value;
		scaleY = value;
		return value;
	}
	
	public function update():Void
	{
		sgn.updateGeometricState(false, false);
	}
	
	public function addChild(child:Tile):TileNode
	{
		D.assert(child != null, 'child is null');
		D.assert(child.sgn.treeNode.parent == null, 'child has a parent, call child.remove() first');
		
		sgn.__node.addChild(child.sgn);
		child.parent = this;
		return this;
	}
	
	public function removeChild(child:Tile):TileNode
	{
		D.assert(child != null, 'child is null');
		D.assert(child.parent == this, 'not a child of this node');
		
		sgn.__node.removeChild(child.sgn);
		child.parent = null;
		return this;
	}
	
	public function addChildAt(child:Tile, index:Int):TileNode
	{
		D.assert(child != null, 'child is null');
		D.assert(child.sgn.treeNode.parent == null, 'child has a parent, call child.remove() first');
		D.assert(index >= 0 && index <= sgn.treeNode.numChildren(), 'index $index out of range');
		
		sgn.__node.addChildAt(child.sgn, index);
		child.parent = this;
		return this;
	}
	
	public function removeChildAt(index:Int):TileNode
	{
		D.assert(sgn.treeNode.hasChildren(), 'node has no children');
		D.assert(index >= 0 || index < sgn.treeNode.numChildren() - 1, 'index $index out of range');
		
		var child = sgn.__node.removeChildAt(index);
		cast(TileManager.ofSpatial(child), Tile).parent = null;
		return this;
	}
	
	public function removeChildren(beginIndex = 0, count = -1):Void
	{
		D.assert(sgn.isNode(), 'no children');
		
		var i = beginIndex + 1;
		var n = count;
		var j = 0;
		var c = sgn.treeNode.children;
		while (j < i)
		{
			c = c.next;
			j++;
		}
		j = 0;
		while (j < n)
		{
			var next = c.next;
			removeChild(cast TileManager.ofSpatial(c.val));
			c = next;
			j++;
		}
	}
	
	public function getChildAt(index:Int):Tile
	{
		D.assert(sgn.treeNode.hasChildren(), 'node has no children');
		D.assert(index >= 0 && index <= sgn.treeNode.numChildren() - 1, 'index $index out of range');
		
		var spatial = sgn.__node.getChildAt(index);
		return cast TileManager.ofSpatial(spatial);
	}
	
	public function getChildIndex(child:Tile):Int
	{
		D.assert(sgn.treeNode.hasChildren(), 'node has no children');
		D.assert(child.sgn.treeNode.parent == sgn.treeNode, 'not a parent of child');
		
		return sgn.__node.getChildIndex(child.sgn);
	}
	
	public function setChildIndex(child:Tile, index:Int):Void
	{
		D.assert(sgn.treeNode.hasChildren(), 'node has no children');
		D.assert(index >= 0 && index < sgn.treeNode.numChildren() - 1, 'index $index out of range');
		
		sgn.__node.setChildIndex(child.sgn, index + 1);
	}
	
	public function getChildById(id:String):Tile
	{
		D.assert(sgn.treeNode.hasChildren(), 'node has no children');
		
		var child = sgn.__node.getChildById(id);
		if (child != null) return cast TileManager.ofSpatial(child);
		return null;
	}
	
	public function swapChildren(child1:Tile, child2:Tile):Void
	{
		D.assert(sgn.treeNode.hasChildren(), 'node has no children');
		
		sgn.__node.swapChildren(child1.sgn, child2.sgn);
	}
	
	public function swapChildrenAt(index1:Int, index2:Int):Void
	{
		D.assert(sgn.treeNode.hasChildren(), 'node has no children');
		
		sgn.__node.swapChildrenAt(index1, index2);
	}
}