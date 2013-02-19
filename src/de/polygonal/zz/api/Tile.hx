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
 
import de.polygonal.core.fmt.Sprintf;
import de.polygonal.core.math.Mathematics;
import de.polygonal.core.sys.Entity;
import de.polygonal.core.util.Assert;
import de.polygonal.ds.TreeNode;
import de.polygonal.gl.color.ColorXForm;
import de.polygonal.zz.scene.AlphaState;
import de.polygonal.zz.scene.Geometry;
import de.polygonal.zz.scene.GlobalStateType;
import de.polygonal.zz.scene.Node;
import de.polygonal.zz.scene.Quad;
import de.polygonal.zz.scene.Spatial;

#if flash11
import de.polygonal.zz.render.module.flash.stage3d.Stage3DRenderer;
#end

//TODO width can be negative!

enum BlendMode
{
	None;
	Inherit;
	Normal;
	Multiply;
	Add;
	Screen;
}

/**
 * A Tile object wraps a <em>Geometry</em> node to provide a simple interface.
 */
class Tile
{
	//TODO clone
	public var geometry(default, null):Geometry;
	
	//initial width and height defined by setColor, setTexture, setSpriteSheet
	var _w0 = 0.; var _h0 = 0.;
	
	//
	var _w1 = 0.;
	var _h1 = 0.;
	
	var _scaleX = 1.;
	var _scaleY = 1.;
	
	var _sgn:Spatial;
	var _blendMode:BlendMode;
	
	public function new(id:String = null)
	{
		geometry = new Quad();
		geometry.id = id;
		_blendMode = BlendMode.Inherit;
	}
	
	public function free():Void
	{
		var e = geometry.effect;
		if (e != null && e.hasTexture())
			RenderSystem.freeTexture(geometry.effect.tex);
		
		geometry.remove();
		geometry.free();
		geometry = null;
	}
	
	public var id(get_id, set_id):String;
	inline function get_id():String
	{
		return geometry.id;
	}
	inline function set_id(value:String):String
	{
		return geometry.id = value;
	}
	
	/**
	 * The x coordinate relative to the local coordinates of the parent object.
	 */
	public var x(get_x, set_x):Float;
	inline function get_x():Float
	{
		return geometry.x;
	}
	inline function set_x(value:Float):Float
	{
		return geometry.x = value;
	}
	
	/**
	 * The y coordinate relative to the local coordinates of the parent object.
	 */
	public var y(get_y, set_y):Float;
	inline function get_y():Float
	{
		return geometry.y;
	}
	inline function set_y(value:Float):Float
	{
		return geometry.y = value;
	}
	
	/**
	 * The rotation in degrees relative to the local coordinates of the parent object.<br/>
	 * Positive rotation is CW.
	 */
	public var rotation(get_rotation, set_rotation):Float;
	inline function get_rotation():Float
	{
		return M.RAD_DEG * geometry.rotation;
	}
	inline function set_rotation(angle:Float):Float
	{
		geometry.rotation = M.DEG_RAD * angle;
		return angle;
	}
	
	/**
	 * The width in pixels.
	 */
	public var width(get_width, set_width):Float;
	inline function get_width():Float
	{
		return M.fabs(_w1);
	}
	inline function set_width(value:Float):Float
	{
		_scaleX = (geometry.scaleX = _w1 = value) / _w0;
		return value;
	}
	
	/**
	 * The height in pixels.
	 */
	public var height(get_height, set_height):Float;
	inline function get_height():Float
	{
		return M.fabs(_h1);
	}
	inline function set_height(value:Float):Float
	{
		_scaleY = (geometry.scaleY = _h1 = value) / _h0;
		return value;
	}
	
	/**
	 * The horizontal scale of the object relative to the pivot point.
	 */
	public var scaleX(get_scaleX, set_scaleX):Float;
	inline function get_scaleX():Float
	{
		return _scaleX;
	}
	inline function set_scaleX(value:Float):Float
	{
		_scaleX = value;
		geometry.scaleX = (_w1 = _w0 * value);
		return value;
	}
	
	/**
	 * The vertical scale of the object relative to the pivot point.
	 */
	public var scaleY(get_scaleY, set_scaleY):Float;
	inline function get_scaleY():Float
	{
		return _scaleY;
	}
	inline function set_scaleY(value:Float):Float
	{
		_scaleY = value;
		geometry.scaleY = (_h1 = _h0 * value);
		return value;
	}
	
	/**
	 * An horizontal offset relative to the origin (top-left corner) of this object.<br/>
	 * The Tile is rotated around and scaled relative to this point.
	 */
	public var centerX(get_centerX, set_centerX):Float;
	inline function get_centerX():Float
	{
		return geometry.centerX;
	}
	inline function set_centerX(value:Float):Float
	{
		return geometry.centerX = value;
	}
	
	/**
	 * An vertical offset relative to the origin (top-left corner) of this object.<br/>
	 * The Tile is rotated around and scaled relative to this point.
	 */
	public var centerY(get_centerY, set_centerY):Float;
	inline function get_centerY():Float
	{
		return geometry.centerY;
	}
	inline function set_centerY(value:Float):Float
	{
		return geometry.centerY = value;
	}
	
	/**
	 * The alpha transparency value in the range [0,1].
	 */
	public var alpha(get_alpha, set_alpha):Float;
	inline function get_alpha():Float
	{
		
		return geometry.effect.alpha;
	}
	inline function set_alpha(value:Float):Float
	{
		geometry.effect.alpha = Mathematics.fclamp(value, 0, 1);
		return value;
	}
	
	public var colorXForm(get_colorXForm, set_colorXForm):ColorXForm;
	inline function get_colorXForm():ColorXForm
	{
		return geometry.effect.colorXForm;
	}
	inline function set_colorXForm(value:ColorXForm):ColorXForm
	{
		geometry.effect.colorXForm = value;
		return value;
	}
	
	public var visible(get_visible, set_visible):Bool;
	inline function get_visible():Bool
	{
		return !geometry.forceCull;
	}
	inline function set_visible(value:Bool):Bool
	{
		geometry.forceCull = value == false;
		return value;
	}
	
	public var blendMode(get_blendMode, set_blendMode):BlendMode;
	inline function get_blendMode():BlendMode
	{
		return _blendMode;
	}
	function set_blendMode(value:BlendMode):BlendMode
	{
		var preMultipliedAlpha = false;
		var e = geometry.effect;
		if (e != null && e.hasTexture())
			preMultipliedAlpha = e.tex.isAlphaPreMultiplied;
		_blendMode = value;
		var state:AlphaState =
		switch (value)
		{
			case BlendMode.Inherit:  null;
			case BlendMode.None:     AlphaState.NONE;
			case BlendMode.Normal:   preMultipliedAlpha ? AlphaState.BLEND_PREMULTIPLIED : AlphaState.BLEND;
			case BlendMode.Multiply: preMultipliedAlpha ? AlphaState.MULTIPLY_PREMULTIPLIED : AlphaState.MULTIPLY;
			case BlendMode.Add:      preMultipliedAlpha ? AlphaState.ADD_PREMULTIPLIED : AlphaState.ADD;
			case BlendMode.Screen:   preMultipliedAlpha ? AlphaState.SCREEN_PREMULTIPLIED : AlphaState.SCREEN;
		}
		if (state == null)
			geometry.removeGlobalState(GlobalStateType.Alpha)
		else
			geometry.setGlobalState(state);
		return value;
	}
	
	public var frameName(get_frameName, set_frameName):String;
	function get_frameName():String
	{
		var e = geometry.effect.__spriteSheetEffect;
		return e.sheet.getFrameName(e.frame);
	}
	function set_frameName(value:String):String
	{
		var e = geometry.effect.__spriteSheetEffect;
		this.frame = e.sheet.getFrameIndex(value);
		return value;
	}
	
	//don't reset size
	public var frame(get_frame, set_frame):Int;
	inline function get_frame():Int
	{
		return geometry.effect.__spriteSheetEffect.frame;
	}
	function set_frame(value:Int):Int
	{
		var e = geometry.effect.__spriteSheetEffect;
		
		#if debug
		D.assert(e != null, 'no sprite sheet effect assigned, call setSpriteSheet() first.');
		#end
		
		e.frame = value;
		var size = e.sheet.getSizeAt(value);
		geometry.scaleX = _w0 = _w1 = size.x * _scaleX;
		geometry.scaleY = _h0 = _h1 = size.y * _scaleY;
		return value;
	}
	
	public function setColor(color:Int, w:Int, h:Int):Tile
	{
		geometry.effect = RenderSystem.createColorEffect(color);
		geometry.scaleX = _w0 = _w1 = w;
		geometry.scaleY = _h0 = _h1 = h;
		_scaleX = _scaleX = 1;
		return this;
	}
	
	public function setTexture(texId:String):Tile
	{
		geometry.effect = RenderSystem.createTextureEffect(texId);
		geometry.scaleX = _w0 = _w1 = geometry.effect.tex.image.w;
		geometry.scaleY = _h0 = _h1 = geometry.effect.tex.image.h;
		_scaleX = _scaleX = 1;
		return this;
	}
	
	public function setSpriteSheet(sheetId:String, initialFrame:Dynamic = null):Tile
	{
		geometry.effect = RenderSystem.createSpriteSheetEffect(sheetId);
		var s = geometry.effect.__spriteSheetEffect.sheet.getSize('0');
		geometry.scaleX = _w0 = _w1 = s.x;
		geometry.scaleY = _h0 = _h1 = s.y;
		_scaleX = _scaleX = 1;
		if (initialFrame != null)
		{
			if (Std.is(initialFrame, String))
				frameName = initialFrame;
			else
			if (Std.is(initialFrame, Int))
				frame = initialFrame;
		}
		return this;
	}
	
	public function alignPivotToCenter():Tile
	{
		geometry.centerX = M.fabs(geometry.scaleX / 2);
		geometry.centerY = M.fabs(geometry.scaleY / 2);
		return this;
	}
	
	public function addChild(child:Tile):Void
	{
		#if debug
		D.assert(child != null, 'child is null');
		D.assert(child._getTreeNode().parent == null, 'child has a parent, call child.remove() first');
		#end
		
		if (_sgn.isGeometry()) _geometryToNode();
		_getNode().addChild(child._sgn);
	}
	
	public function removeChild(child:Tile):Void
	{
		#if debug
		D.assert(child != null, 'child is null');
		D.assert(child._getTreeNode().parent != null, 'child has no parent');
		#end
		
		if (!_sgn.isGeometry()) _getNode().removeChild(child._sgn);
	}
	
	public function addChildAt(child:Tile, index:Int):Void
	{
		#if debug
		D.assert(child != null, 'child is null');
		D.assert(child._getTreeNode().parent == null, 'child has a parent, call child.remove() first');
		#end
		
		if (_sgn.isGeometry())
		{
			#if debug
			D.assert(index != 0, Sprintf.format('index %d out of range', [index]));
			#end
			
			addChild(child);
		}
		else
		{
			#if debug
			D.assert(index >= 0 || index < _getTreeNode().numChildren(), Sprintf.format('index %d out of range', [index]));
			#end
			
			if (_sgn.isGeometry()) _geometryToNode();
			_getNode().addChildAt(child._sgn, index + 1);
		}
	}
	
	public function removeChildAt(index:Int):Void
	{
		#if debug
		D.assert(index >= 0 || index < _getTreeNode().numChildren() - 1, Sprintf.format('index %d out of range', [index]));
		#end
		
		if (!_sgn.isGeometry()) _getNode().removeChildAt(index + 1);
	}
	
	public function removeChildren(beginIndex = 0, count = -1):Void
	{
		#if debug
		D.assert(_sgn.isNode(), 'no children');
		#end
		
		_getNode().removeChildren(beginIndex + 1, count);
	}
	
	public function getChildAt(index:Int):Tile
	{
		#if debug
		D.assert(index >= 0 && index <= _getTreeNode().numChildren() - 1, Sprintf.format('index %d out of range', [index]));
		#end
		
		return _getNode().getChildAt(index).userData;
	}
	
	public function getChildIndex(child:Tile):Int
	{
		#if debug
		D.assert(child._getTreeNode().parent == _getTreeNode(), 'not a parent of child');
		#end
		
		var i = _getNode().getChildIndex(child._sgn);
		if (child._sgn.isGeometry()) i--;
		return i;
	}
	
	public function setChildIndex(child:Tile, index:Int):Void
	{
		#if debug
		D.assert(index >= 0 && index < _getTreeNode().numChildren() - 1, Sprintf.format('index %d out of range', [index]));
		#end
		
		_getNode().setChildIndex(child._sgn, index + 1);
	}
	
	public function getChildById(id:String):Tile
	{
		#if debug
		D.assert(_sgn.isNode(), 'no children');
		#end
		
		return _getNode().getChildById(id).userData;
	}
	
	public function swapChildren(child1:Tile, child2:Tile):Void
	{
		_getNode().swapChildren(child1._sgn, child2._sgn);
	}
	
	public function swapChildrenAt(index1:Int, index2:Int):Void
	{
		_getNode().swapChildrenAt(index1, index2);
	}
	
	function _geometryToNode():Void
	{
		//replace a geometry leaf with a "group" node whenever a child
		//is added in order to keep the scene graph as small as possible.
		//otherwise each object would be composed of a group node and a geometry node,
		//wasting processing time and memory.
		var geometry = _sgn;
		geometry.userData = null;
		
		//unlink this geometry from parent node
		var parent = geometry.remove();
		
		//replace geometry with node
		var node = new Node();
		node.userData = this;
		node.id = id;
		
		if (parent != null) parent.addChild(node);
		node.addChild(geometry);
		
		//copy transformation geometry => node
		node.x = geometry.x;
		node.y = geometry.y;
		node.rotation = geometry.rotation;
		
		//zero out geometry transformation
		geometry.x = 0;
		geometry.y = 0;
		geometry.rotation = 0;
		geometry.id = id;
		
		//replace geometry
		_sgn = node;
	}
	
	inline function _getNode():Node
	{
		return _sgn.__node;
	}
	
	inline function _getTreeNode():TreeNode<Spatial>
	{
		return _sgn.treeNode;
	}
}