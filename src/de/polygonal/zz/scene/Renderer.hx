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

import de.polygonal.core.math.Mat44;
import de.polygonal.core.math.Mathematics;
import de.polygonal.ds.Bits;
import de.polygonal.ds.DA;
import de.polygonal.gl.color.ColorRGBA;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.effect.SpriteSheetEffect;
import de.polygonal.zz.render.effect.TextureEffect;
import de.polygonal.zz.render.texture.Image;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.scene.Geometry;
import de.polygonal.zz.scene.Node;
import de.polygonal.zz.scene.Spatial;
import de.polygonal.zz.render.RenderSurface;
import de.polygonal.core.util.Assert;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.Vector;
import flash.Vector;

using de.polygonal.ds.BitFlags;

/**
 * A custom renderer must implement this renderer.
 */
class Renderer
{
	/**
	 * Viewport width in pixels.
	 */
	public var width(default, null):Int;
	
	/**
	 * Viewport height in pixels.
	 */
	public var height(default, null):Int;
	
	public var currScene(default, null):Node;
	public var currNode(default, null):Node;
	public var currGeometry(default, null):Geometry;
	public var currEffect(default, null):Effect;
	public var currGlobalEffect(default, null):Effect;
	public var currMVP(default, null):Mat44;
	public var currViewProjMatrix(default, null):Mat44;
	public var currTexture:Tex;
	
	public var drawDeferred:Void->Void;
	
	public var numCulledObjects:Int;

	/**
	 * If true, culling is disabled. Default is false.
	 */
	public var noCulling = false;
	
	public var allowGlobalState:Bool;
	public var allowAlphaState:Bool;
	public var allowTextures:Bool;
	
	public var currAlphaState:AlphaState;
	
	var _camera:Camera;
	var _viewMatrix:Mat44;
	var _projMatrix:Mat44;
	var _backgroundColor:ColorRGBA;
	var _deferredObjects:DA<Spatial>;
	var _textureLookup:IntHash<Tex>;
	
	public function new(width:Int, height:Int)
	{
		if (RenderSurface.isReady() == false) throw 'Surface not initialized.';
		if (RenderSurface.isResizable()) RenderSurface.onResize = function(w, h) resize(w, h);
		
		this.width = width;
		this.height = height;
		
		currMVP = new Mat44();
		currScene = null;
		currNode = null;
		currGeometry = null;
		currEffect = null;
		currGlobalEffect = null;
		currViewProjMatrix = new Mat44();
		drawDeferred = null;
		allowGlobalState = true;
		allowAlphaState = true;
		allowTextures = true;
		_deferredObjects = new DA();
		
		currAlphaState = new AlphaState(AlphaState.SrcBlendFactor.Zero, AlphaState.DstBlendFactor.Zero);
		currAlphaState.key = -1;
		
		_viewMatrix = new Mat44();
		_projMatrix = new Mat44();
		_backgroundColor = new ColorRGBA(1, 1, 1, 1);
		_textureLookup = new IntHash();
		
		setCamera(new Camera());
		onViewPortChange();
	}
	
	public function free():Void
	{
		currScene = null;
		currNode = null;
		currGeometry = null;
		currEffect = null;
		currGlobalEffect = null;
		currMVP = null;
		currViewProjMatrix = null;
		drawDeferred = null;
		
		_viewMatrix = null;
		_projMatrix = null;
		_backgroundColor = null;
		_deferredObjects.free();
		_deferredObjects = null;
		
		if (_camera != null)
		{
			_camera.free();
			_camera = null;
		}
	}
	
	inline public function getCamera():Camera
	{
		return _camera;
	}
	
	public function setCamera(camera:Camera):Void
	{
		_camera = camera;
		_camera.setRenderer(this);
	}
	
	public function setBackgroundColor(r:Float, g:Float, b:Float, a:Float):Void
	{
		_backgroundColor.x = r;
		_backgroundColor.y = g;
		_backgroundColor.z = b;
		_backgroundColor.w = a;
	}
	
	public function resize(width:Int, height:Int):Void
	{
		this.width = width;
		this.height = height;
		onViewPortChange();
	}
	
	public function setGlobalState(state:DA<GlobalState>):Void
	{
		if (state == null) return;
		
		if (allowAlphaState)
		{
			var state = state.get(Type.enumIndex(GlobalStateType.Alpha));
			if (state != null)
			{
				var alphaState = state.__alphaState;
				if (alphaState.key != currAlphaState.key)
				{
					setAlphaState(state.__alphaState);
					currAlphaState = alphaState;
				}
			}
		}
	}
	
	public function setAlphaState(state:AlphaState):Void
	{
	}
	
	public function drawScene(scene:Node):Void
	{
		if (scene == null || _camera == null) return;
		
		//precompute view-projection matrix (camera coordinates => homogeneous coordinates)
		Mat44.matrixProduct(_projMatrix, _viewMatrix, currViewProjMatrix);
		
		currScene = scene;
		
		onBeginScene();
		
		numCulledObjects = 0;
		scene.cull(this, noCulling);
		
		if (drawDeferred != null)
		{
			drawDeferred();
			_deferredObjects.clear();
		}
		
		onEndScene();
		
		//clear Spatial.BIT_WORLD_CHANGED, BIT_MODEL_CHANGED flag
		scene.treeNode.preorder();
	}
	
	public function drawNode(node:Node):Void
	{
		if (drawDeferred == null)
		{
			currNode = node;
			currGlobalEffect = node.effect;
			
			#if debug
			D.assert(currGlobalEffect != null, 'currGlobalEffect != null');
			#end
			
			currGlobalEffect.draw(this);
			
			currNode = null;
			currGlobalEffect = null;
		}
		else
			_deferredObjects.pushBack(node);
	}
	
	public function drawGeometry(geometry:Geometry):Void
	{
		if (drawDeferred == null)
		{
			currGeometry = geometry;
			currEffect = geometry.effect;
			
			if (currEffect != null)
				currEffect.draw(this);
			else
				drawPrimitive();
			
			currEffect = null;
			currGeometry = null;
		}
		else
			_deferredObjects.pushBack(geometry);
	}
	
	public function drawPrimitive():Void
	{
		//TODO only invoked when no effect available
		var geometry = currGeometry;
		
		if (allowGlobalState)
			setGlobalState(geometry.states);
		
		if (allowTextures && currEffect != null)
			currTexture = currEffect.tex;
		
		drawElements();
	}
	
	public function drawDeferredRegular():Void
	{
		//disable deferred drawing
		var save = drawDeferred;
		drawDeferred = null;
		
		for (o in _deferredObjects)
		{
			if (o.isGeometry()) drawGeometry(o.__geometry);
			if (o.isNode()) drawNode(o.__node);
		}
		
		//restore deferred drawing
		drawDeferred = save;
	}
	
	public function drawDeferredBatch():Void
	{
	}

	public function drawEffect(effect:Effect):Void
	{
		if (allowGlobalState) setGlobalState(currGeometry.states);
	}
	
	public function drawTextureEffect(effect:TextureEffect):Void
	{
		if (allowGlobalState) setGlobalState(currGeometry.states);
	}
	
	public function drawSpriteSheetEffect(effect:SpriteSheetEffect):Void
	{
		if (allowGlobalState) setGlobalState(currGeometry.states);
	}
	
	/**
	 * Computes the MVP (model-view-projection) matrix for <code>spatial</code> and stores the result in <em>currMVP</em>.
	 * @return a reference to <code>currMVP</code>.
	 */
	public function setModelViewProjMatrix(spatial:Spatial):Mat44
	{
		//steps to go from model to clip space (starting with model coordinates):
		//1. apply model matrix => world coodinates
		//2. apply view matrix => camera coordinates
		//3. apply projection matrix => homogeneous coordinates
		
		//set MVP (model-view-projection) matrix
		
		//1.) convert transformation to 4x4 matrix
		getModelMatrix(spatial, currMVP);
		
		//2.) concatenate with view and projection matrix
		currMVP.cat(currViewProjMatrix);
		
		return currMVP;
	}
	
	/**
	 * Computes the combined model-to-world matrix from <code>spatial</code>'s world transformation
	 * and stores the result in <code>output</code>.
	 * @return a reference to <code>output</code>.
	 */
	public function getModelMatrix(spatial:Spatial, output:Mat44):Mat44
	{
		var xform = spatial.world;
		
		#if debug
		D.assert(!xform.isIdentity(), '!xform.isIdentity()');
		#end
		
		if (spatial.hasf(Spatial.BIT_USE_2D_XFORM))
		{
			if (xform.isRSMatrix())
			{
				var r = xform.getRotate();
				var s = xform.getScale();
				var t = s.x;
				output.m11 = t * r.m11;
				output.m21 = t * r.m21;
				output.m31 = 0;
				t = s.y;
				output.m12 = t * r.m12;
				output.m22 = t * r.m22;
				output.m32 = 0;
				output.m13 = 0;
				output.m23 = 0;
				output.m33 = 0;
			}
			else
			{
				var r = xform.getMatrix();
				output.m11 = r.m11;
				output.m21 = r.m21;
				output.m31 = 0;
				output.m12 = r.m12;
				output.m22 = r.m22;
				output.m32 = 0;
				output.m13 = r.m13;
				output.m23 = r.m23;
				output.m33 = 0;
			}
			
			output.m41 = 0;
			output.m42 = 0;
			output.m43 = 0;
			
			var t = xform.getTranslate();
			output.m14 = t.x;
			output.m24 = t.y;
			output.m34 = 0;
			output.m44 = 1;
		}
		else
		{
			if (xform.isRSMatrix())
			{
				var r = xform.getRotate();
				var s = xform.getScale();
				var t = s.x;
				output.m11 = t * r.m11;
				output.m21 = t * r.m21;
				output.m31 = t * r.m31;
				t = s.y;
				output.m12 = t * r.m12;
				output.m22 = t * r.m22;
				output.m32 = t * r.m32;
				t = s.z;
				output.m13 = t * r.m13;
				output.m23 = t * r.m23;
				output.m33 = t * r.m33;
			}
			else
			{
				var r = xform.getMatrix();
				output.m11 = r.m11;
				output.m21 = r.m21;
				output.m31 = r.m31;
				output.m12 = r.m12;
				output.m22 = r.m22;
				output.m32 = r.m32;
				output.m13 = r.m13;
				output.m23 = r.m23;
				output.m33 = r.m33;
			}
			
			output.m41 = 0;
			output.m42 = 0;
			output.m43 = 0;
			
			var t = xform.getTranslate();
			output.m14 = t.x;
			output.m24 = t.y;
			output.m34 = t.z;
			output.m44 = 1;
		}
		
		return output;
	}
	
	public function onViewPortChange():Void
	{
		_projMatrix.setOrtho(-width / 2, width / 2, -height / 2, height / 2, 0, 1);
		
		//screen coordinates where the origin is at the upper-left corner of the screen
		_projMatrix.catScale(1, -1, 1);
		_projMatrix.catTranslate(-1, 1, 0);
	}
	
	public function onFrameChange():Void
	{
		var t = _camera.local.getTranslate();
		
		_viewMatrix.setIdentity();
		_viewMatrix.catScale(_camera.zoom, _camera.zoom, 1.);
		_viewMatrix.catTranslate(-t.x, -t.y, 0.);
		_viewMatrix.catRotateZ(_camera.rotation);
	}
	
	/**
	 * Resolves a texture for a given <code>image</code>.<br/>
	 * If a texture doesn't exist yet, a new one is created and cached for repeated use.
	 */
	public function getTex(image:Image):Tex
	{
		var tex = _textureLookup.get(image.key);
		if (tex == null)
		{
			tex = createTex(image);
			_textureLookup.set(image.key, tex);
		}
		return tex;
	}
	
	public function freeTex(image:Image):Void
	{
		var tex = _textureLookup.get(image.key);
		if (tex != null)
		{
			tex.free();
			_textureLookup.remove(image.key);
		}
	}
	
	function onBeginScene()
	{
	}
	
	function onEndScene()
	{
	}
	
	function drawElements()
	{
	}
	
	function createTex(image:Image):Tex
	{
		return throw 'override for implementation';
	}
}