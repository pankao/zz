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
package de.polygonal.zz.render.module.flash.cpu;

import de.polygonal.core.util.Assert;
import de.polygonal.ds.DLL;
import de.polygonal.ds.DLLNode;
import de.polygonal.ds.IntHashTable;
import de.polygonal.gl.color.ColorRGBA;
import de.polygonal.zz.render.effect.Effect.*;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.effect.SpriteSheetEffect;
import de.polygonal.zz.render.effect.TextureEffect;
import de.polygonal.zz.render.RenderSurface;
import de.polygonal.zz.render.texture.Image;
import de.polygonal.zz.render.texture.Rect;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.scene.Renderer;
import de.polygonal.zz.scene.Spatial;
import de.polygonal.zz.scene.XForm;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Lib;

using de.polygonal.ds.BitFlags;

class DisplayListRenderer extends Renderer
{
	public var canvas(default, null):Sprite;
	
	var _tileLookup:IntHashTable<TileData>;
	var _bitmapLookup:IntHashTable<BitmapTile>;
	var _bitmapList:DLL<BitmapTile>;
	
	var _zIndex:Int;
	
	var _scratchMatrix:Matrix;
	var _scratchColorTransform:ColorTransform;
	var _scratchColorTransformAlpha:ColorTransform;
	var _scratchRect:Rectangle;
	var _scratchPoint:Point;
	var _scratchShape:Shape;
	var _scratchXForm:XForm;
	
	public function new(width = 0, height = 0)
	{
		super(width, height);
		
		canvas = new Sprite();
		canvas.mouseChildren = false;
		canvas.mouseEnabled = false;
		
		_scratchMatrix = new Matrix();
		_scratchColorTransform = new ColorTransform();
		_scratchColorTransformAlpha = new ColorTransform();
		_scratchRect = new Rectangle();
		_scratchPoint = new Point();
		_tileLookup = new IntHashTable(512, 512, false, 512);
		_scratchShape = new Shape();
		_scratchXForm = new XForm();
		
		_bitmapLookup = new IntHashTable<BitmapTile>(512, 512, false, 512);
		
		_bitmapList = new DLL<BitmapTile>();
		
		drawDeferred = null;
		
		RenderSurface.root.addChild(canvas);
	}
	
	override public function free():Void
	{
		super.free();
		
		_scratchMatrix = null;
		_scratchColorTransform = null;
		_scratchColorTransformAlpha = null;
		_scratchRect = null;
		_scratchPoint = null;
		_scratchShape = null;
		
		_tileLookup.free();
		_tileLookup = null;
	}
	
	override public function setBackgroundColor(r:Float, g:Float, b:Float, a:Float):Void
	{
		super.setBackgroundColor(r, g, b, a);
		
		canvas.graphics.clear();
		
		if (a == 0) return;
		
		canvas.graphics.beginFill(ColorRGBA.toRGB(_backgroundColor), a);
		canvas.graphics.drawRect(0, 0, width, height);
		canvas.graphics.endFill();
	}
	
	override public function createTex(image:Image):Tex
	{
		return new Tex(image, false, false);
	}
	
	override public function drawEffect(effect:Effect):Void
	{
		//SRT transform
		var world = currGeometry.world;
		var s = world.getScale();
		var r = world.getRotate();
		var t = world.getTranslate();
		
		if (currGeometry.rotation == 0)
		{
			var color =
			if (effect.alpha == 1)
				(0xff << 24) | effect.color;
			else
				(cast(effect.alpha * 0xff) << 24) | effect.color;
			
			if (effect.flags & EFFECT_COLOR_XFORM > 0)
				color = effect.colorXForm.transformRGBA(color);
			
			_scratchRect.x = t.x;
			_scratchRect.y = t.y;
			_scratchRect.width = s.x;
			_scratchRect.height = s.y;
			//canvas.fillRect(_scratchRect, color);
			return;
		}
		
		var shape = _scratchShape;
		shape.graphics.clear();
		shape.graphics.beginFill(effect.color, effect.alpha);
		shape.graphics.drawRect(0, 0, s.x, s.y);
		
		var flashMatrix = transformationToMatrix(world, s.x, s.y, _scratchMatrix);
		var flashColorTransform = getColorTransform(effect);
	}
	
	override public function drawTextureEffect(effect:TextureEffect):Void
	{
		var bmp = getBitmap(currGeometry);
		
		var uv = effect.crop;
		var tex = effect.tex;
		var tileData = getTile(tex.key, tex, uv);
		
		var world = currGeometry.world;
		var s = world.getScale();
		var r = world.getRotate();
		var t = world.getTranslate();
		
		var flashMatrix = transformationToMatrix(world, uv.w, uv.h, _scratchMatrix);
		
		bmp.setData(tileData);
		bmp.visible = true;
		bmp.alpha = effect.alpha;
		sortZ(bmp);
		
		if (effect.flags & Effect.EFFECT_COLOR_XFORM > 0)
			bmp.transform.colorTransform = getColorTransform(effect);
		else
		if (effect.flags & Effect.EFFECT_ALPHA > 0)
			bmp.alpha = effect.alpha;
		
		bmp.transform.matrix = flashMatrix;
	}
	
	override public function drawSpriteSheetEffect(effect:SpriteSheetEffect):Void
	{
		var bmp = getBitmap(currGeometry);
		
		var uv = effect.crop;
		var tex = effect.tex;
		
		var tileData = getTile(effect.frame << 16 | tex.key, tex, uv);
		
		var world = currGeometry.world;
		var s = world.getScale();
		var r = world.getRotate();
		var t = world.getTranslate();
		
		var flashMatrix = transformationToMatrix(world, uv.w, uv.h, _scratchMatrix);
		
		bmp.setData(tileData);
		bmp.visible = true;
		bmp.alpha = effect.alpha;
		sortZ(bmp);
		
		if (effect.flags & Effect.EFFECT_COLOR_XFORM > 0)
			bmp.transform.colorTransform = getColorTransform(effect);
		else
		if (effect.flags & Effect.EFFECT_ALPHA > 0)
			bmp.alpha = effect.alpha;
		
		//fast blitting if no rotation, scale and effects
		/*if (currGeometry.rotation == 0)
		{
			if (s.x == uv.w && s.y == uv.h)
			{
				if (effect.flags == EFFECT_TEXTURE)
				{
					_scratchPoint.x = t.x;
					_scratchPoint.y = t.y;
					_bitmap.copyPixels(tileData.b, tileData.r, _scratchPoint, null, null, true);
					return;
				}
			}
			
			bmp.x = t.x;
			bmp.y = t.y;
			//bmp.scaleX = s.x;
			//bmp.scaleY = s.y;
		}
		else*/
		bmp.transform.matrix = flashMatrix;
	}
	
	override public function onViewPortChange():Void
	{
		_projMatrix.setIdentity();
	}
	
	override function onBeginScene():Void
	{
		var node = _bitmapList.head;
		while (node != null)
		{
			node.val.visible = false;
			node = node.next;
		}
		
		_zIndex = 0;
	}
	
	override function onEndScene():Void
	{
		var node = _bitmapList.head;
		while (node != null)
		{
			var x:BitmapTile = node.val;
			
			if (x.visible)
			{
				node = node.next;
				continue;
			}
			
			var next = node.next;
			
			//freed or removed from scene graph?
			var treeNode = x.spatial.treeNode;
			if (treeNode == null || treeNode.parent == null)
			{
				x.free();
				_bitmapLookup.remove(x);
			}
			
			node = next;
		}
	}
	
	inline function transformationToMatrix(xf:XForm, w:Float, h:Float, m:Matrix):Matrix
	{
		//matrix layout
		//|a c tx|
		//|b d ty|
		//|u v w |
		
		#if debug
		D.assert(xf.isRSMatrix(), 'xf.isRSMatrix()');
		#end
		
		var frame = getCamera().local;
		if (!frame.isIdentity())
		{
			_scratchXForm.product(frame, xf);
			_scratchXForm.setf(XForm.BIT_HINT_RS_MATRIX);
			xf = _scratchXForm;
		}
		
		var r = xf.getRotate();
		var s = xf.getScale();
		var sx = (s.x / w) * 1.001; //hack: required for bitmap smoothing
		m.a = sx * r.m11;
		m.b = sx * r.m21;
		var sy = (s.y / h) * 1.001; //hack: required for bitmap smoothing
		m.c = sy * r.m12;
		m.d = sy * r.m22;
		var v = xf.getTranslate();
		m.tx = v.x;
		m.ty = v.y;
		
		return m;
	}
	
	inline function getColorTransform(effect:Effect):ColorTransform
	{
		var flags = effect.flags;
		var ct = null;
		if (flags & EFFECT_ALPHA > 0)
		{
			ct = _scratchColorTransformAlpha;
			ct.alphaMultiplier = effect.alpha;
			
			if (flags & EFFECT_COLOR_XFORM > 0)
				ct.concat(convert(effect));
		}
		else
		if (flags & EFFECT_COLOR_XFORM > 0)
			ct = convert(effect);
		return ct;
	}
	
	inline function convert(effect:Effect):ColorTransform
	{
		var ct = _scratchColorTransform;
		
		var m = effect.colorXForm.multiplier;
		ct.redMultiplier   = m.r;
		ct.greenMultiplier = m.g;
		ct.blueMultiplier  = m.b;
		ct.alphaMultiplier = m.a * effect.alpha;
		
		var o = effect.colorXForm.offset;
		ct.redOffset   = o.r;
		ct.greenOffset = o.g;
		ct.blueOffset  = o.b;
		ct.alphaOffset = o.a;
		
		return ct;
	}
	
	inline function sortZ(x:BitmapTile):Void
	{
		if (x.zIndex != _zIndex)
			canvas.setChildIndex(x, _zIndex);
		x.zIndex = _zIndex;
		_zIndex++;
	}
	
	inline function getBitmap(spatial:Spatial):BitmapTile
	{
		var bmp = _bitmapLookup.get(spatial.key);
		if (bmp == null)
			return initBitmap(spatial);
		else
			return bmp;
	}
	
	inline function getTile(key:Int, tex:Tex, uv:Rect):TileData
	{
		var tile = _tileLookup.get(key);
		if (tile == null)
			return initTile(key, tex, uv);
		else
			return tile;
	}
	
	function initBitmap(spatial:Spatial):BitmapTile
	{
		var bmp = new BitmapTile();
		bmp.spatial = spatial;
		_bitmapLookup.set(spatial.key, bmp);
		canvas.addChild(bmp);
		
		bmp.listNode = _bitmapList.append(bmp);
		
		return bmp;
	}
	
	function initTile(key:Int, tex:Tex, uv:Rect):TileData
	{
		trace( "DisplayListRenderer.initTile > key : " + key + ", tex : " + tex + ", uv : " + uv );
		_scratchRect.x = uv.x;
		_scratchRect.y = uv.y;
		_scratchRect.width = uv.w;
		_scratchRect.height = uv.h;
		_scratchPoint.x = 0;
		_scratchPoint.y = 0;
		
		var bmd = new BitmapData(cast uv.w, cast uv.h, true, 0);
		bmd.copyPixels(tex.image.data, _scratchRect, _scratchPoint);
		
		var tile = new TileData(key, bmd, bmd.rect.clone());
		_tileLookup.set(key, tile);
		return tile;
	}
}

private class BitmapTile extends Bitmap
{
	public var key:Int;
	public var spatial:Spatial;
	public var listNode:DLLNode<BitmapTile>;
	public var zIndex:Int;
	
	public function new()
	{
		super(null, flash.display.PixelSnapping.NEVER, true);
		key = -1;
		spatial = null;
		listNode = null;
		zIndex = -1;
	}
	
	inline public function setData(x:TileData):Void
	{
		if (x.key != key)
		{
			key = x.key;
			bitmapData = x.bitmapData;
			smoothing = true;
		}
	}
	
	public function free():Void
	{
		if (parent != null) parent.removeChild(this);
		spatial = null;
		listNode.unlink();
		listNode.free();
		listNode = null;
	}
}

private class TileData
{
	public var key:Int;
	public var bitmapData:BitmapData;
	public var rect:Rectangle;
	
	public function new(key:Int, bitmapData:BitmapData, rect:Rectangle)
	{
		this.key = key;
		this.bitmapData = bitmapData;
		this.rect = rect;
	}
}