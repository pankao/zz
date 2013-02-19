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
package de.polygonal.zz;

import de.polygonal.zz.scene.AlphaState;
import de.polygonal.zz.scene.Node;
import de.polygonal.zz.scene.Renderer;
import de.polygonal.zz.scene.Spatial;

using de.polygonal.ds.BitFlags;

typedef SceneFriend =
{
	private var _sgn:Spatial;
}

class Scene extends Flat
{
	override function get_width():Float 
	{
		return 0;
	}
	
	override function set_width(w:Float):Float
	{
		throw 'unsupported operation';
		return 0;
	}
	
	override function get_height():Float 
	{
		return 0;
	}
	
	override function set_height(h:Float):Float
	{
		throw 'unsupported operation';
		return 0;
	}
	
	//TODO don't allow color
	
	var _renderer:Renderer;
	
	public function new()
	{
		super(1, 1);
	}
	
	public function setRenderer(renderer:Renderer):Void
	{
		_renderer = renderer;
	}

	public function update():Void
	{
		//make sure all transformations and bounding volumes are current
		
		//very inefficient "brute-force" sg-update, useful for debugging
		_sgn.updateGeometricState(true);
		_sgn.updateRenderState();
		
		//intelligent update for render mode!
		
		//intelligent recursive sg update algorithm
		_sgn.treeNode.preorder(
			function(node:TreeNode<Spatial>, preflight:Bool, userData:Dynamic):Bool
			{
				if (preflight)
				{
					//use Tile flag instead
					//if (node.val.hasf(Spatial.BIT_LOCAL_CHANGED))
					//{
						node.val.updateGeometricState(true);
						return false; //exclude subtree from traversal
					//}
					return true;
				}
				return true;
			}, true);
		
		//intelligent iterative sg update algorithm
		/*var stack = new Array<TreeNode<Spatial>>();
		stack[0] = _sgn.treeNode.children;
		var top = 1;
		while (top != 0)
		{
			var node = stack[--top];
			var spatial = node.val;
			if (spatial.hasf(Spatial.BIT_LOCAL_CHANGED))
			{
				spatial.updateGeometricState(true);
				continue;
			}
			var n = node.children;
			while (n != null)
			{
				stack[top++] = n;
				n = n.next;
			}
		}*/
	}
	
	public function render():Void
	{
		//_renderer.drawScene(_getNode());
	}
	
/*	public function addChild(child:Flat):Void
	{
		_sgn.addChild(_getNode(child));
		
		update();
	}
	
	public function addChildAt(child:Flat, index:Int):Void
	{
		_sgn.addChildAt(_getNode(child), index);
		
		update();
	}
	
	
	public function removeChild(child:Flat):Void
	{
		_sgn.removeChild(_getNode(child));
		
		update();
	}
	
	inline function getNode(f:SceneFriend) return f._sgn*/
	
	override function createSceneGraphNode()
	{
		var n = new Node();
		n.id = 'scene';
		n.userData = this;
		_sgn = n;
		
		//var state = new AlphaState();
		//_sgn.setGlobalState(state);
	}
}