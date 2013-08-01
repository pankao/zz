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

import de.polygonal.core.math.Mat44;
import de.polygonal.core.util.Assert;
import de.polygonal.ds.ArrayedStack;
import de.polygonal.ds.DA;
import de.polygonal.ds.TreeNode;
import de.polygonal.gl.color.ColorRGBA;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.effect.SpriteSheetEffect;
import de.polygonal.zz.render.effect.TextureEffect;
import de.polygonal.zz.render.module.RenderModuleConfig;
import de.polygonal.zz.render.RenderSurface;
import de.polygonal.zz.render.texture.Image;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.scene.Geometry;
import de.polygonal.zz.scene.Node;
import de.polygonal.zz.scene.Spatial;
import haxe.ds.IntMap;

using de.polygonal.ds.BitFlags;
using Reflect;

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
	
	/**
	 * The current scene graph being drawn.<br/>
	 */
	public var currScene(default, null):Node;
	public var currNode(default, null):Node;
	public var currGeometry(default, null):Geometry;
	public var currEffect(default, null):Effect;
	public var currGlobalEffect(default, null):Effect;
	public var currMVP(default, null):Mat44;
	public var currViewProjMatrix(default, null):Mat44;
	public var currTexture(default, null):Tex;
	
	public var drawDeferred:Void->Void;
	
	public var numCallsToDrawGeometry:Int;
	public var numCulledObjects:Int;

	/**
	 * If true, culling is disabled. Default is false.
	 */
	public var noCulling = false;
	
	public var allowGlobalState = true;
	public var allowAlphaState = true;
	public var allowTextures = true;
	
	public var currAlphaState:AlphaState;
	
	public var maxBatchSize(default, null):Int = 4096;
	
	var _camera:Camera;
	var _viewMatrix:Mat44;
	var _projMatrix:Mat44;
	var _backgroundColor:ColorRGBA;
	
	var _deferredDrawingActive:Bool;
	var _deferredObjectsList:Spatial;
	var _deferredObjectsNode:Spatial;
	
	var _textureLookup:IntMap<Tex>;
	
	var _scratchStack:ArrayedStack<TreeNode<Spatial>>;
	
	public function new(config:RenderModuleConfig)
	{
		if (RenderSurface.isReady() == false) throw 'Surface not initialized.';
		RenderSurface.onResize = function(w, h) resize(w, h);
		
		width = RenderSurface.width;
		height = RenderSurface.height;
		if (config != null)
		{
			if (config.hasField('width')) width = config.width;
			if (config.hasField('height')) height = config.height;
		}
		
		maxBatchSize = 4096;
		
		currMVP = new Mat44();
		currScene = null;
		currNode = null;
		currGeometry = null;
		currEffect = null;
		currGlobalEffect = null;
		currViewProjMatrix = new Mat44();
		drawDeferred = null;
		
		_deferredObjectsList = new Node('deferredList');
		_deferredObjectsNode = null;
		
		currAlphaState = null;
		
		_viewMatrix = new Mat44();
		_projMatrix = new Mat44();
		_backgroundColor = new ColorRGBA(1, 1, 1, 1);
		_textureLookup = new IntMap();
		
		_scratchStack = new ArrayedStack<TreeNode<Spatial>>();
		
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
		
		var node = _deferredObjectsList;
		while (node != null)
		{
			var next = node.__next;
			node.__next = null;
			node = next;
		}
		_deferredObjectsList = null;
		_deferredObjectsNode = null;
		
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
	
	public function clear()
	{
	}
	
	public function resize(width:Int, height:Int):Void
	{
		this.width = width;
		this.height = height;
		onViewPortChange();
	}
	
	public function setGlobalState(states:DA<GlobalState>):Void
	{
		if (allowAlphaState)
		{
			if (states == null)
			{
				if (currAlphaState != null)
				{
					setAlphaState(AlphaState.NONE);
					currAlphaState = null;
				}
			}
			else
			{
				var state = states.get(Type.enumIndex(GlobalStateType.Alpha));
				
				if (state == null)
				{
					if (currAlphaState != null)
					{
						setAlphaState(AlphaState.NONE);
						currAlphaState = null;
					}
					return;
				}
				
				if (currAlphaState == null || state.equals(currAlphaState))
				{
					var alphaState = state.__alphaState;
					setAlphaState(alphaState);
					currAlphaState = alphaState;
				}
			}
		}
	}
	
	function setAlphaState(state:AlphaState):Void
	{
		throw 'override for implementation';
	}
	
	public function drawScene(scene:Node):Void
	{
		if (scene == null || _camera == null) return;
		
		//precompute view-projection matrix (camera coordinates => homogeneous coordinates)
		Mat44.matrixProduct(_projMatrix, _viewMatrix, currViewProjMatrix);
		
		currScene = scene;
		
		numCallsToDrawGeometry = 0;
		
		onBeginScene();
		
		_deferredObjectsList.__next = null;
		_deferredObjectsNode = _deferredObjectsList;
		
		numCulledObjects = 0;
		scene.cull(this, noCulling);
		
		//terminate list
		_deferredObjectsNode.__next = null;
		
		if (drawDeferred != null)
		{
			_deferredDrawingActive = true;
			drawDeferred();
			_deferredDrawingActive = false;
		}
		
		onEndScene();
		
		_deferredObjectsList.__next = null;
		_deferredObjectsNode = null;
		
		//clear flags
		/*var s = _scratchStack;
		s.clear();
		s.push(scene.treeNode.children);
		while (s.size() > 0)
		{
			var node = s.pop();
			var spatial = node.val;
			spatial.clrf(Spatial.BIT_WORLD_CHANGED | Spatial.BIT_MODEL_CHANGED);
			k++;
			var n = node.children;
			while (n != null)
			{
				s.push(n);
				n = n.next;
			}
		}*/
	}
	
	public function drawNode(node:Node):Void
	{
		//draw instantly
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
			return;
		}
		
		//accumulate for deferred drawing (append to list)
		_deferredObjectsNode = _deferredObjectsNode.__next = node;
	}
	
	public function drawGeometry(geometry:Geometry):Void
	{
		//if deferred drawing is active, insert geometry into list of deferred objects
		if (_deferredDrawingActive)
		{
			var next = _deferredObjectsNode.__next;
			_deferredObjectsNode.__next = geometry;
			geometry.__next = next;
			_deferredObjectsNode = geometry;
			return;
		}
		
		if (drawDeferred == null)
		{
			//draw instantly
			currGeometry = geometry;
			currEffect = geometry.effect;
			
			if (currEffect != null)
				currEffect.draw(this);
			else
				drawPrimitive();
			
			currEffect = null;
			currGeometry = null;
			return;
		}
		else
		{
			//accumulate
			_deferredObjectsNode = _deferredObjectsNode.__next = geometry;
		}
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
		
		throw 'todo';
		/*for (o in _deferredObjects)
		{
			if (o.isGeometry()) drawGeometry(o.__geometry);
			if (o.isNode()) drawNode(o.__node);
		}*/
		
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
	
	//TODO only recompute if changed
	
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
		
		if (xform.isIdentity())
		{
			output.setIdentity();
			return output;
		}
		
		if (spatial.useZ)
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
		else
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
		
		return output;
	}
	
	public function onViewPortChange():Void
	{
		_projMatrix.setOrthoSimple(width, height, -1, 1);
		_projMatrix.catScale(1, -1, 1);
		//_projMatrix.catTranslate(-1, 1, 1);
	}
	
	public function onFrameChange():Void
	{
		_viewMatrix.setIdentity();
		_viewMatrix.catScale(_camera.scaleX, _camera.scaleY, 1);
		_viewMatrix.catRotateZ(_camera.rotation);
		_viewMatrix.catTranslate(_camera.x, _camera.y, 0);
	}
	
	/**
	 * Resolves a texture for a given <code>image</code>.<br/>
	 * If a texture doesn't exist yet, a new one is created and cached for repeated use.
	 */
	public function initTex(image:Image):Tex
	{
		var tex = _textureLookup.get(image.key);
		if (tex == null)
		{
			tex = createTex(image);
			L.d(Printf.format('create texture #%d from image "%s" (#%d)', [tex.key, image.id, image.key]));
			_textureLookup.set(image.key, tex);
		}
		return tex;
	}
	
	public function freeTex(image:Image):Void
	{
		var tex = _textureLookup.get(image.key);
		if (tex != null)
		{
			L.d(Printf.format('free texture #%d (image "%s", #%d)', [tex.key, image.id, image.key]));
			tex.free();
			_textureLookup.remove(image.key);
		}
	}
	
	function onBeginScene():Void
	{
	}
	
	function onEndScene():Void
	{
	}
	
	function drawElements():Void
	{
	}
	
	function createTex(image:Image):Tex
	{
		return throw 'override for implementation';
	}
}