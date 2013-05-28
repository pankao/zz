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
import de.polygonal.core.util.Assert;
import de.polygonal.ds.TreeNode;
import de.polygonal.gl.color.ColorXForm;
import de.polygonal.zz.scene.AlphaState;
import de.polygonal.zz.scene.Geometry;
import de.polygonal.zz.scene.GlobalStateType;
import de.polygonal.zz.scene.Node;
import de.polygonal.zz.scene.Quad;
import de.polygonal.zz.scene.Spatial;

using de.polygonal.core.math.Mathematics;

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
	/*static var _tileLookup:IntMap<Tile> = new IntMap<Tile>();
	
	inline public static function findTile(x:Spatial):Tile
	{
		return _tileLookup.get(x.key);
	}*/
	
	/**
	 * The geometry node that this Tile is controlling.
	 */
	public var spatial(default, null):Geometry;
	
	//width and height defined by applyColor, appyTexture, applySpriteSheet
	var _w:Float;
	var _h:Float;
	
	//current scaling factor
	var _sX:Float;
	var _sY:Float;
	
	//current center point
	var _cX:Float;
	var _cY:Float;
	
	var _sgn:Spatial;
	var _blendMode:BlendMode;
	var _smooth:Bool;
	
	public function new(id:String = null)
	{
		_w = _cX = 0;
		_h = _cY = 0;
		_sX = 1;
		_sY = 1;
		
		spatial = new Quad();
		spatial.id = id;
		_blendMode = BlendMode.Inherit;
		_smooth = true;
		
		//_tileLookup.set(spatial.key, this);
	}
	
	public function free():Void
	{
		if (spatial == null) return;
		
		var e = spatial.effect;
		if (e != null && e.hasTexture())
			RenderSystem.freeTexture(spatial.effect.tex);
		
		//_tileLookup.remove(spatial.key);
		
		spatial.remove();
		spatial.free();
		spatial = null;
	}
	
	public var id(get_id, set_id):String;
	inline function get_id():String return spatial.id;
	inline function set_id(value:String):String return spatial.id = value;
	
	/**
	 * The x coordinate relative to the local coordinates of the parent object.
	 */
	public var x(get_x, set_x):Float;
	inline function get_x():Float return spatial.x;
	inline function set_x(value:Float):Float return spatial.x = value;
	
	/**
	 * The y coordinate relative to the local coordinates of the parent object.
	 */
	public var y(get_y, set_y):Float;
	inline function get_y():Float return spatial.y;
	inline function set_y(value:Float):Float return spatial.y = value;
	
	/**
	 * The rotation in degrees relative to the local coordinates of the parent object.<br/>
	 * Positive rotation is CW.
	 */
	public var rotation(get_rotation, set_rotation):Float;
	inline function get_rotation():Float return M.RAD_DEG * spatial.rotation;
	inline function set_rotation(angle:Float):Float
	{
		spatial.rotation = M.DEG_RAD * angle;
		return angle;
	}
	
	/**
	 * The width in pixels.
	 */
	public var width(get_width, set_width):Float;
	inline function get_width():Float return M.fabs(_w * _sX);
	inline function set_width(value:Float):Float
	{
		D.assert(_w != 0, 'use applyColor(), applyTexture() or applySpriteSheet to define an initial width/height');
		
		_sX = value / _w;
		spatial.scaleX = value;
		spatial.centerX = _cX * _sX;
		return value;
	}
	
	/**
	 * The height in pixels.
	 */
	public var height(get_height, set_height):Float;
	inline function get_height():Float return M.fabs(_h * _sY);
	inline function set_height(value:Float):Float
	{
		D.assert(_h != 0, 'use applyColor(), applyTexture() or applySpriteSheet to define an initial width/height');
		
		_sY = value / _h;
		spatial.scaleY = value;
		spatial.centerY = _cY * _sY;
		return value;
	}
	
	public var size(get_size, set_size):Float;
	function get_size():Float
	{
		D.assert(_w == _h, 'width and height mismatch');
		
		return _w;
	}
	function set_size(value:Float):Float
	{
		D.assert(_w != 0, 'use applyColor(), applyTexture() or applySpriteSheet to define an initial width/height');
		
		width = value;
		height = value;
		return value;
	}
	
	/**
	 * The horizontal scale of the object relative to the center point.
	 */
	public var scaleX(get_scaleX, set_scaleX):Float;
	inline function get_scaleX():Float return _sX;
	inline function set_scaleX(value:Float):Float
	{
		D.assert(_w != 0, 'use applyColor(), applyTexture() or applySpriteSheet to define an initial width/height');
		
		_sX = value;
		spatial.scaleX = _w * value;
		spatial.centerX = _cX * value.fabs();
		return value;
	}
	
	/**
	 * The vertical scale of the object relative to the center point.
	 */
	public var scaleY(get_scaleY, set_scaleY):Float;
	inline function get_scaleY():Float return _sY;
	inline function set_scaleY(value:Float):Float
	{
		D.assert(_h != 0, 'use applyColor(), applyTexture() or applySpriteSheet to define an initial width/height');
		
		_sY = value;
		spatial.scaleY = _h * value;
		spatial.centerY = _cY * value;
		return value;
	}
	
	public var scale(get_scale, set_scale):Float;
	inline function get_scale():Float
	{
		D.assert(_sX == _sY, 'scaleX and scaleY mismatch');
		return _sX;
	}
	inline function set_scale(value:Float):Float
	{
		scaleX = value;
		scaleY = value;
		return value;
	}
	
	//TODO scaleAbs, scaleSgn
	
	/**
	 * An horizontal offset relative to the origin (top-left corner) of this <b>unscaled</b> tile.<br/>
	 * The Tile is rotated around and scaled relative to this point.
	 */
	public var centerX(get_centerX, set_centerX):Float;
	inline function get_centerX():Float
	{
		return _cX;
	}
	inline function set_centerX(value:Float):Float
	{
		_cX = value;
		spatial.centerX = value;
		return value;
	}
	
	/**
	 * An vertical offset relative to the origin (top-left corner) of this <b>unscaled</b> tile.<br/>
	 * The Tile is rotated around and scaled relative to this point.
	 */
	public var centerY(get_centerY, set_centerY):Float;
	inline function get_centerY():Float
	{
		return _cY;
	}
	inline function set_centerY(value:Float):Float
	{
		_cY = value;
		spatial.centerY = value;
		return value;
	}
	
	/**
	 * The alpha transparency value in the range [0,1].
	 */
	public var alpha(get_alpha, set_alpha):Float;
	inline function get_alpha():Float return spatial.effect.alpha;
	inline function set_alpha(value:Float):Float
	{
		spatial.effect.alpha = Mathematics.fclamp(value, 0, 1);
		return value;
	}
	
	public var colorXForm(get_colorXForm, set_colorXForm):ColorXForm;
	inline function get_colorXForm():ColorXForm return spatial.effect.colorXForm;
	inline function set_colorXForm(value:ColorXForm):ColorXForm
	{
		spatial.effect.colorXForm = value;
		return value;
	}
	
	public var visible(get_visible, set_visible):Bool;
	inline function get_visible():Bool return !spatial.forceCull;
	inline function set_visible(value:Bool):Bool
	{
		spatial.forceCull = value == false;
		return value;
	}
	
	public var blendMode(get_blendMode, set_blendMode):BlendMode;
	inline function get_blendMode():BlendMode return _blendMode;
	function set_blendMode(value:BlendMode):BlendMode
	{
		var preMultipliedAlpha = false;
		var e = spatial.effect;
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
			spatial.removeGlobalState(GlobalStateType.Alpha)
		else
			spatial.setGlobalState(state);
		return value;
	}
	
	public var frameName(get_frameName, set_frameName):String;
	function get_frameName():String
	{
		var e = spatial.effect.__spriteSheetEffect;
		return e.sheet.getFrameName(e.frame);
	}
	function set_frameName(value:String):String
	{
		var e = spatial.effect.__spriteSheetEffect;
		
		D.assert(e != null, 'no sprite sheet effect assigned, call setSpriteSheet() first.');
		
		this.frame = e.sheet.getFrameIndex(value);
		return value;
	}
	
	public var frame(get_frame, set_frame):Int;
	inline function get_frame():Int return spatial.effect.__spriteSheetEffect.frame;
	function set_frame(value:Int):Int
	{
		var e = spatial.effect.__spriteSheetEffect;
		
		D.assert(e != null, 'no sprite sheet effect assigned, call setSpriteSheet() first.');
		
		e.frame = value;
		
		var size = e.sheet.getSizeAt(value);
		_w = size.x;
		_h = size.y;
		
		spatial.scaleX = _w * scaleX;
		spatial.scaleY = _h * scaleY;
		
		return value;
	}
	
	public var smooth(get_smooth, set_smooth):Bool;
	inline function get_smooth():Bool return _smooth;
	function set_smooth(value:Bool):Bool
	{
		_smooth = value;
		if (spatial.effect != null)
			spatial.effect.smooth = value;
		return value;
	}
	
	/**
	 * Apply a solid color fill to this tile.<br/>
	 * The scaling factor and the center point are left unmodified.
	 * @param rgb the color in RRGGBB format (little endian, blue in lowest 8 bits).
	 * @param width the width of this tile.
	 * @param height the height of this tile.
	 */
	public function applyColor(rgb:Int, width:Int, height:Int):Tile
	{
		spatial.effect = RenderSystem.createColorEffect(rgb);
		#if nme
		spatial.effect.smooth = _smooth;
		#end
		
		_w = width;
		_h = height;
		
		spatial.scaleX = _w * scaleX;
		spatial.scaleY = _h * scaleY;
		
		return this;
	}
	
	/**
	 * Apply a texture to this tile.<br/>
	 * The scaling factor and the center point are left unmodified.
	 */
	public function applyTexture(texId:String, useTextureSize = true):Tile
	{
		spatial.effect = RenderSystem.createTextureEffect(texId);
		#if nme
		spatial.effect.smooth = _smooth;
		#end
		
		if (useTextureSize)
		{
			_w = spatial.effect.tex.image.w;
			_h = spatial.effect.tex.image.h;
		}
		
		spatial.scaleX = _w * scaleX;
		spatial.scaleY = _h * scaleY;
		
		return this;
	}
	
	public function applySpriteSheet(sheetId:String, initialFrame:Dynamic = null):Tile
	{
		spatial.effect = RenderSystem.createSpriteSheetEffect(sheetId);
		#if nme
		spatial.effect.smooth = _smooth;
		#end
		var s = spatial.effect.__spriteSheetEffect.sheet.getSize('0');
		spatial.scaleX = _w = s.x;
		spatial.scaleY = _h = s.y;
		_sX = _sX = 1;
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
	
	public function resetTransform():Void
	{
		D.assert(_w != 0 && _h != 0, 'use applyColor(), applyTexture() or applySpriteSheet to define an initial width/height');
		
		_sX = 1;
		_sY = 1;
		_cX = 0;
		_cY = 0;
		rotation = 0;
		
		spatial.scaleX = _w;
		spatial.scaleY = _h;
		spatial.centerX = 0;
		spatial.centerY = 0;
	}
	
	/**
	 *  Moves the pivot point P from the origin (=top-left corner) to to the center of this tile.
	 *   P-----+------> x     +-----+
	 *   |     |              |     |
	 *   |     |              |  P-------> x
	 *   |     |              |  |  |
	 *   +-----+              +--|--+
	 *   |                       |
	 *   |                       |
	 *   v                       v
	 */
	public function centerPivot(noShift = false):Void
	{
		_cX = spatial.centerX = M.fabs(spatial.scaleX * .5);
		_cY = spatial.centerY = M.fabs(spatial.scaleY * .5);
		
		if (noShift)
		{
			x += width  * .5;
			y += height * .5;
		}
	}
	
	public function resetPivot():Void
	{
		_cX = spatial.centerX = 0;
		_cY = spatial.centerY = 0;
	}
	
	public function update():Void
	{
		//spatial.scaleX = _curW;
		//spatial.scaleY = _curH;
		
		spatial.updateGeometricState(false, false);
	}
	
	public function addChild(child:Tile):Void
	{
		D.assert(child != null, 'child is null');
		D.assert(child._getTreeNode().parent == null, 'child has a parent, call child.remove() first');
		
		if (_sgn.isGeometry()) _geometryToNode();
		_getNode().addChild(child._sgn);
	}
	
	public function removeChild(child:Tile):Void
	{
		D.assert(child != null, 'child is null');
		D.assert(child._getTreeNode().parent != null, 'child has no parent');
		
		if (!_sgn.isGeometry()) _getNode().removeChild(child._sgn);
	}
	
	public function addChildAt(child:Tile, index:Int):Void
	{
		D.assert(child != null, 'child is null');
		D.assert(child._getTreeNode().parent == null, 'child has a parent, call child.remove() first');
		
		if (_sgn.isGeometry())
		{
			D.assert(index != 0, Sprintf.format('index %d out of range', [index]));
			
			addChild(child);
		}
		else
		{
			D.assert(index >= 0 || index < _getTreeNode().numChildren(), Sprintf.format('index %d out of range', [index]));
			
			if (_sgn.isGeometry()) _geometryToNode();
			_getNode().addChildAt(child._sgn, index + 1);
		}
	}
	
	public function removeChildAt(index:Int):Void
	{
		D.assert(index >= 0 || index < _getTreeNode().numChildren() - 1, Sprintf.format('index %d out of range', [index]));
		
		if (!_sgn.isGeometry()) _getNode().removeChildAt(index + 1);
	}
	
	public function removeChildren(beginIndex = 0, count = -1):Void
	{
		D.assert(_sgn.isNode(), 'no children');
		
		_getNode().removeChildren(beginIndex + 1, count);
	}
	
	public function getChildAt(index:Int):Tile
	{
		D.assert(index >= 0 && index <= _getTreeNode().numChildren() - 1, Sprintf.format('index %d out of range', [index]));
		
		return _getNode().getChildAt(index).userData;
	}
	
	public function getChildIndex(child:Tile):Int
	{
		D.assert(child._getTreeNode().parent == _getTreeNode(), 'not a parent of child');
		
		var i = _getNode().getChildIndex(child._sgn);
		if (child._sgn.isGeometry()) i--;
		return i;
	}
	
	public function setChildIndex(child:Tile, index:Int):Void
	{
		D.assert(index >= 0 && index < _getTreeNode().numChildren() - 1, Sprintf.format('index %d out of range', [index]));
		
		_getNode().setChildIndex(child._sgn, index + 1);
	}
	
	public function getChildById(id:String):Tile
	{
		D.assert(_sgn.isNode(), 'no children');
		
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