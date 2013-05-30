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
import de.polygonal.core.util.Assert;
import de.polygonal.gl.color.ColorXForm;
import de.polygonal.zz.render.texture.Size;
import de.polygonal.zz.scene.AlphaState;
import de.polygonal.zz.scene.Geometry;
import de.polygonal.zz.scene.GlobalStateType;
import de.polygonal.zz.scene.Quad;

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

//TODO scaleAbs, scaleSgn
//TODO resolve tile from sgn
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
	public var sgn(default, null):Geometry;
	
	public var parent(default, null):TileNode;
	
	var _width:Float;
	var _height:Float;
	var _scaleX:Float;
	var _scaleY:Float;
	var _centerX:Float;
	var _centerY:Float;
	
	var _blendMode:BlendMode;
	var _smooth:Bool;
	var _trimOffset:Size;
	
	public function new(id:String = null)
	{
		_width = _centerX = 0;
		_height = _centerY = 0;
		_scaleX = 1;
		_scaleY = 1;
		
		parent = null;
		sgn = new Quad();
		sgn.id = id;
		_blendMode = BlendMode.Inherit;
		_smooth = true;
		
		//_tileLookup.set(sgn.key, this);
	}
	
	public function free():Void
	{
		if (sgn == null) return;
		
		var e = sgn.effect;
		if (e != null && e.hasTexture())
			RenderSystem.freeTexture(sgn.effect.tex);
		
		//_tileLookup.remove(sgn.key);
		
		sgn.remove();
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
	
	/**
	 * The width in pixels.
	 */
	public var width(get_width, set_width):Float;
	inline function get_width():Float return M.fabs(_width * _scaleX);
	inline function set_width(value:Float):Float
	{
		D.assert(_width != 0, 'use applyColor(), applyTexture() or applySpriteSheet to define an initial width/height');
		
		_scaleX = value / _width;
		sgn.scaleX = value;
		sgn.centerX = _centerX * _scaleX;
		return value;
	}
	
	/**
	 * The height in pixels.
	 */
	public var height(get_height, set_height):Float;
	inline function get_height():Float return M.fabs(_height * _scaleY);
	inline function set_height(value:Float):Float
	{
		D.assert(_height != 0, 'use applyColor(), applyTexture() or applySpriteSheet to define an initial width/height');
		
		_scaleY = value / _height;
		sgn.scaleY = value;
		sgn.centerY = _centerY * _scaleY;
		return value;
	}
	
	public var size(get_size, set_size):Float;
	function get_size():Float
	{
		D.assert(_width == _height, 'width != height');
		
		return _width;
	}
	function set_size(value:Float):Float
	{
		D.assert(_width != 0, 'use applyColor(), applyTexture() or applySpriteSheet to define an initial width/height');
		
		width = value;
		height = value;
		return value;
	}
	
	/**
	 * The horizontal scale of the object relative to the center point.
	 */
	public var scaleX(get_scaleX, set_scaleX):Float;
	inline function get_scaleX():Float return _scaleX;
	inline function set_scaleX(value:Float):Float
	{
		D.assert(_width != 0, 'use applyColor(), applyTexture() or applySpriteSheet to define an initial width/height');
		
		_scaleX = value;
		sgn.scaleX = _width * value;
		sgn.centerX = _centerX * value.fabs();
		//sgn.x = _x + _lX * value;
		return value;
	}
	
	/**
	 * The vertical scale of the object relative to the center point.
	 */
	public var scaleY(get_scaleY, set_scaleY):Float;
	inline function get_scaleY():Float return _scaleY;
	inline function set_scaleY(value:Float):Float
	{
		D.assert(_height != 0, 'use applyColor(), applyTexture() or applySpriteSheet to define an initial width/height');
		
		_scaleY = value;
		sgn.scaleY = _height * value;
		sgn.centerY = _centerY * value;
		//sgn.y = _x + _lY * value;
		return value;
	}
	
	public var scale(get_scale, set_scale):Float;
	inline function get_scale():Float
	{
		D.assert(_scaleX == _scaleY, 'scaleX != scaleY');
		return _scaleX;
	}
	inline function set_scale(value:Float):Float
	{
		scaleX = value;
		scaleY = value;
		return value;
	}
	
	/**
	 * An horizontal offset relative to the origin (top-left corner) of this <b>unscaled</b> tile.<br/>
	 * The Tile is rotated around and scaled relative to this point.
	 */
	public var centerX(get_centerX, set_centerX):Float;
	inline function get_centerX():Float
	{
		return _centerX;
	}
	inline function set_centerX(value:Float):Float
	{
		_centerX = value;
		sgn.centerX = value;
		return value;
	}
	
	/**
	 * An vertical offset relative to the origin (top-left corner) of this <b>unscaled</b> tile.<br/>
	 * The Tile is rotated around and scaled relative to this point.
	 */
	public var centerY(get_centerY, set_centerY):Float;
	inline function get_centerY():Float
	{
		return _centerY;
	}
	inline function set_centerY(value:Float):Float
	{
		_centerY = value;
		sgn.centerY = value;
		return value;
	}
	
	/**
	 * The alpha transparency value in the range [0,1].
	 */
	public var alpha(get_alpha, set_alpha):Float;
	inline function get_alpha():Float return sgn.effect.alpha;
	inline function set_alpha(value:Float):Float
	{
		sgn.effect.alpha = Mathematics.fclamp(value, 0, 1);
		return value;
	}
	
	public var colorXForm(get_colorXForm, set_colorXForm):ColorXForm;
	inline function get_colorXForm():ColorXForm return sgn.effect.colorXForm;
	inline function set_colorXForm(value:ColorXForm):ColorXForm
	{
		sgn.effect.colorXForm = value;
		return value;
	}
	
	public var visible(get_visible, set_visible):Bool;
	inline function get_visible():Bool return !sgn.forceCull;
	inline function set_visible(value:Bool):Bool
	{
		sgn.forceCull = value == false;
		return value;
	}
	
	public var blendMode(get_blendMode, set_blendMode):BlendMode;
	inline function get_blendMode():BlendMode return _blendMode;
	function set_blendMode(value:BlendMode):BlendMode
	{
		var preMultipliedAlpha = false;
		var e = sgn.effect;
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
			sgn.removeGlobalState(GlobalStateType.Alpha)
		else
			sgn.setGlobalState(state);
		return value;
	}
	
	public var frameName(get_frameName, set_frameName):String;
	function get_frameName():String
	{
		var e = sgn.effect.__spriteSheetEffect;
		return e.sheet.getFrameName(e.frame);
	}
	function set_frameName(value:String):String
	{
		var e = sgn.effect.__spriteSheetEffect;
		
		D.assert(e != null, 'no sprite sheet effect assigned, call setSpriteSheet() first.');
		
		this.frame = e.sheet.getFrameIndex(value);
		return value;
	}
	
	public var frame(get_frame, set_frame):Int;
	inline function get_frame():Int return sgn.effect.__spriteSheetEffect.frame;
	function set_frame(value:Int):Int
	{
		var e = sgn.effect.__spriteSheetEffect;
		
		D.assert(e != null, 'no sprite sheet effect assigned, call setSpriteSheet() first.');
		
		e.frame = value;
		
		var sheet = e.sheet;
		
		var size = sheet.getSizeAt(value);
		_width = size.x;
		_height = size.y;
		
		_trimOffset = null;
		if (sheet.isTrimmed(value))
			_trimOffset = sheet.getTrimOffsetAt(value);
		
		sgn.scaleX = _width * scaleX;
		sgn.scaleY = _height * scaleY;
		
		return value;
	}
	
	public var smooth(get_smooth, set_smooth):Bool;
	inline function get_smooth():Bool return _smooth;
	function set_smooth(value:Bool):Bool
	{
		_smooth = value;
		if (sgn.effect != null)
			sgn.effect.smooth = value;
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
		sgn.effect = RenderSystem.createColorEffect(rgb);
		#if nme
		sgn.effect.smooth = _smooth;
		#end
		
		_width = width;
		_height = height;
		
		sgn.scaleX = _width * scaleX;
		sgn.scaleY = _height * scaleY;
		
		return this;
	}
	
	/**
	 * Apply a texture to this tile.<br/>
	 * The scaling factor and the center point are left unmodified.
	 */
	public function applyTexture(texId:String, useTextureSize = true):Tile
	{
		sgn.effect = RenderSystem.createTextureEffect(texId);
		#if nme
		sgn.effect.smooth = _smooth;
		#end
		
		if (useTextureSize)
		{
			_width = sgn.effect.tex.image.w;
			_height = sgn.effect.tex.image.h;
		}
		
		sgn.scaleX = _width * scaleX;
		sgn.scaleY = _height * scaleY;
		
		return this;
	}
	
	public function applySpriteSheet(sheetId:String, initialFrame:Dynamic = null):Tile
	{
		sgn.effect = RenderSystem.createSpriteSheetEffect(sheetId);
		#if nme
		sgn.effect.smooth = _smooth;
		#end
		
		var sheet = sgn.effect.__spriteSheetEffect.sheet;
		
		var frameIndex = 0;
		if (initialFrame != null)
		{
			frameIndex =
			if (Std.is(initialFrame, String))
				sheet.getFrameIndex(initialFrame);
			else
				cast(initialFrame, Int);
		}
		
		_trimOffset = null;
		if (sheet.isTrimmed(frameIndex))
			_trimOffset = sheet.getTrimOffsetAt(frameIndex);
		
		//TODO keep scaling
		//TODO reset center?
		var s = sheet.getSizeAt(frameIndex);
		sgn.scaleX = _width = s.x;
		sgn.scaleY = _height = s.y;
		_scaleX = _scaleX = 1;
		
		frame = frameIndex;
		return this;
	}
	
	public function resetTransform():Void
	{
		D.assert(_width != 0 && _height != 0, 'use applyColor(), applyTexture() or applySpriteSheet to define an initial width/height');
		_scaleX = 1;
		_scaleY = 1;
		_centerX = 0;
		_centerY = 0;
		rotation = 0;
		sgn.x = 0;
		sgn.y = 0;
		sgn.scaleX = _width;
		sgn.scaleY = _height;
		sgn.centerX = 0;
		sgn.centerY = 0;
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
		if (_trimOffset != null)
		{
			var e = sgn.effect.__spriteSheetEffect;
			var size = e.sheet.getUntrimmedSizeAt(e.frame);
			_centerX = sgn.centerX = M.fabs(size.x * .5) + _trimOffset.x;
			_centerY = sgn.centerY = M.fabs(size.y * .5) + _trimOffset.y;
			
			if (noShift)
			{
				x += size.x * .5;
				y += size.y * .5;
			}
		}
		else
		{
			_centerX = sgn.centerX = M.fabs(sgn.scaleX * .5);
			_centerY = sgn.centerY = M.fabs(sgn.scaleY * .5);
			
			if (noShift)
			{
				x += width  * .5;
				y += height * .5;
			}
		}
	}
	
	public function resetPivot():Void
	{
		_centerX = sgn.centerX = 0;
		_centerY = sgn.centerY = 0;
	}
	
	public function update():Void
	{
		//sgn.scaleX = _curW;
		//sgn.scaleY = _curH;
		
		sgn.updateGeometricState(false, false);
	}
	
	public function remove():Void
	{
		sgn.remove();
	}
}