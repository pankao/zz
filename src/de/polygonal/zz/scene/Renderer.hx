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

using de.polygonal.ds.BitFlags;

/**
 * A custom renderer must implement this renderer.
 */
class Renderer
{
	inline public static var TYPE_FLASH_SOFTWARE = Bits.BIT_01;
	inline public static var TYPE_FLASH_HARDWARE = Bits.BIT_02;
	inline public static var TYPE_NME_TILES      = Bits.BIT_03;
	inline public static var TYPE_HTML5_CANVAS   = Bits.BIT_04;
	
	public static var type = 0;
	
	public var currScene(default, null):Node;
	public var currNode(default, null):Node;
	public var currGeometry(default, null):Geometry;
	public var currEffect(default, null):Effect;
	public var currGlobalEffect(default, null):Effect;
	public var currMVP(default, null):Mat44;
	public var currViewProjMatrix(default, null):Mat44;
	public var currTexture:Tex;
	
	public var drawDeferred:Void->Void;

	/**
	 * If true, culling is disabled. Default is false.
	 */
	public var noCulling:Bool;
	
	public var allowGlobalState:Bool;
	public var allowAlphaState:Bool;
	public var allowTextures:Bool;
	
	public var currAlphaState:AlphaState;
	
	/**
	 * Drawable surface and window dimensions.
	 */
	public var surface(default, null):RenderSurface;
	
	public var camera(get_camera, set_camera):Camera;
	inline function get_camera():Camera
	{
		return _camera;
	}
	function set_camera(value:Camera):Camera
	{
		_camera = value;
		if (_camera != null)
		{
			var friend:{private var _renderer:Renderer;} = _camera;
			friend._renderer = this;
		}
		return value;
	}
	
	var _viewMatrix:Mat44;
	var _projMatrix:Mat44;
	
	var _camera:Camera;
	var _backgroundColor:ColorRGBA;
	var _deferredObjects:DA<Spatial>;
	
	var _textureLookup:IntHash<Tex>;
	
	public function new()
	{
		if (!RenderSurface.isReady()) throw 'Surface not initialized.';
		
		if (RenderSurface.isResizable())
			RenderSurface.onResize = function(w, h) resize(w, h);
		
		currMVP = new Mat44();
		currScene = null;
		currNode = null;
		currGeometry = null;
		currEffect = null;
		currGlobalEffect = null;
		currViewProjMatrix = new Mat44();
		
		currAlphaState = new AlphaState(AlphaState.SrcBlendFactor.Zero, AlphaState.DstBlendFactor.Zero);
		currAlphaState.key = -1;
		
		_camera = null;
		_viewMatrix = new Mat44();
		_projMatrix = new Mat44();
		_backgroundColor = new ColorRGBA(1, 1, 1, 1);
		_textureLookup = new IntHash();
		
		noCulling = false;
		drawDeferred = null;
		allowGlobalState = true;
		allowAlphaState = true;
		allowTextures = true;
		_deferredObjects = new DA();
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
	
	/**
	 * Make this renderer the active one.
	 */
	public function activate():Void
	{
		Renderer.type = getType();
		
		onViewPortChange();
		
		//view frustum -> projection matrix
		onFrustumChange();
		
		if (_camera != null) onFrameChange();
	}
	
	public function setBackgroundColor(r:Float, g:Float, b:Float, a:Float):Void
	{
		_backgroundColor.x = r;
		_backgroundColor.y = g;
		_backgroundColor.z = b;
		_backgroundColor.w = a;
	}
	
	public function resize(w:Int, h:Int):Void
	{
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
	
	public function setAlphaState(state:AlphaState):Void {}
	
	//var perspectiveProjectionMatrix:Matrix3D;
	//var orthoProjectionMatrix:Matrix3D;
	
	public function drawScene(scene:Node):Void
	{
		if (scene == null || _camera == null) return;
		
		//orthoProjectionMatrix = makeOrtographicMatrix(0, surface.w, 0, surface.h);
		//trace(printMatrix3D(orthoProjectionMatrix));
		
		//+0.0025    +0.0000    +0.0000    +0.0000   
		//+0.0000    -0.0033    +0.0000    +0.0000   
		//+0.0000    +0.0000    +1.0000    +0.0000   
		//+0.0000    +0.0000    +0.0000    +1.0000
		
		//n =0, f = 1
		//+0.0025    +0.0000    +0.0000    +0.0000   
		//+0.0000    +0.0033    +0.0000    +0.0000   
		//+0.0000    +0.0000    -2.0000    -1.0000   
		//+0.0000    +0.0000    +0.0000    +1.0000   
	
		/*var f = _camera.frustum;
		throw f;
		var m = new Mat44();
		m.setOrtho(f.left, f.right, f.bottom, f.top, f.near, f.far);
		trace(m);*/
		
		//_projMatrix.setOrtho(f.left, f.right, f.bottom, f.top, f.near, f.far);
		
		/*var fovDegree = 60.0;
		var magicNumber = Math.tan((fovDegree * 0.5) * de.polygonal.core.math.Mathematics.DEG_RAD);
		var projMat:Matrix3D = makeProjectionMatrix(0.1, 2000.0, fovDegree, surface.w / surface.h);
		var lookAtPosition:Vector3D = new Vector3D(0.0, 0.0, 0.0);
		// zEye distance from origin: sceneHeight * 0.5 / tan(a) 
		var eye = new Vector3D(0, 0, -(surface.h * 0.5) / magicNumber);
		var lookAtMat:Matrix3D = lookAt(lookAtPosition, eye);
		lookAtMat.append(projMat);
		perspectiveProjectionMatrix = lookAtMat;
		var m = getViewProjectionMatrix(true);
		currViewProjMatrix.ofVector(m.rawData);*/
		
		//precompute view-projection matrix (camera coordinates => homogeneous coordinates)
		Mat44.matrixProduct(_projMatrix, _viewMatrix, currViewProjMatrix);
		
		currScene = scene;
		
		onBeginScene();
		
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
	
	
	/*public function printMatrix3D(m:Matrix3D):String
	{
		var a = m.rawData;
		
		var format = '\nMat44\n' +
			'%-+10.4f %-+10.4f %-+10.4f %-+10.4f\n' +
			'%-+10.4f %-+10.4f %-+10.4f %-+10.4f\n' +
			'%-+10.4f %-+10.4f %-+10.4f %-+10.4f\n' +
			'%-+10.4f %-+10.4f %-+10.4f %-+10.4f\n';
		return de.polygonal.core.fmt.Sprintf.format(format,
			[a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10], a[11], a[12], a[13], a[14], a[15]]);
	}*/
	
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
	
	/**
	 * 
	 */
	public function freeTex(image:Image):Void
	{
		var tex = _textureLookup.get(image.key);
		if (tex != null)
		{
			tex.free();
			_textureLookup.remove(image.key);
		}
	}
	
	function createTex(image:Image):Tex
	{
		//implement in subclass.
		return throw 'override for implementation';
	}
	
	/*function lookAt(lookAt:Vector3D, position:Vector3D):Matrix3D
	{
		var up:Vector3D = new Vector3D();
		up.x = Math.sin(0.0);
		up.y = -Math.cos(0.0);
		up.z = 0;
		
		var forward:Vector3D = new Vector3D();
		forward.x = lookAt.x - position.x;
		forward.y = lookAt.y - position.y;
		forward.z = lookAt.z - position.z;
		forward.normalize();

		var right:Vector3D = up.crossProduct(forward);
		right.normalize();

		up = right.crossProduct(forward);
		up.normalize();

		var rawData = new Vector<Float>();
		rawData.push(-right.x);
		rawData.push(-right.y);
		rawData.push(-right.z);
		rawData.push(0);
		
		rawData.push(up.x);
		rawData.push(up.y);
		rawData.push(up.z);
		rawData.push(0);
		
		rawData.push(-forward.x);
		rawData.push(-forward.y);
		rawData.push(-forward.z);
		rawData.push(0);
		
		rawData.push(0);
		rawData.push(0);
		rawData.push(0);
		rawData.push(1);

		var mat:Matrix3D = new Matrix3D(rawData);
		mat.prependTranslation(-position.x, -position.y, -position.z);

		return mat;
	}*/
	/*function makeProjectionMatrix(zNear:Float, zFar:Float, fovDegrees:Float, aspect:Float):Matrix3D
	{
		var yval:Float = zNear * Math.tan(fovDegrees * (Math.PI / 360.0));
		var xval:Float = yval * aspect;
		return makeFrustumMatrix(-xval, xval, -yval, yval, zNear, zFar);
	}*/
	/*function makeFrustumMatrix(left:Float, right:Float, top:Float, bottom:Float, zNear:Float, zFar:Float):Matrix3D
	{
		var values:flash.Vector<Float> = Vector.ofArray(
		[
								(2 * zNear) / (right - left),
								0,
								(right + left) / (right - left),
								0,

								0,
								(2 * zNear) / (top - bottom),
								(top + bottom) / (top - bottom),
								0,

								0,
								0,
								zFar / (zNear - zFar),
								-1,

								0,
								0,
								(zNear * zFar) / (zNear - zFar),
								0
							]);
		return new Matrix3D(values);
		throw 1;
		return null;
	}*/
	/*function makeOrtographicMatrix(left:Float, right:Float, top:Float, bottom:Float, zNear:Float = 0, zFar:Float = 1):Matrix3D
	{
		var values:flash.Vector<Float> = Vector.ofArray(
			[
				2 / (right - left), 0, 0,  0,
				0,  2 / (top - bottom), 0, 0,
				0,  0, 1 / (zFar - zNear), 0,
				0, 0, zNear / (zNear - zFar), 1
			]);
			return new Matrix3D(values);
		return null;
	}*/
	
	/*public function getViewProjectionMatrix(useOrthoMatrix:Bool):Matrix3D
	{
		var x = 0;
		var y = 0;
		var zoom = 1;
		var rotation = 0;
		var viewMatrix = new Matrix3D();
		viewMatrix.identity();
		viewMatrix.appendTranslation(-surface.w / 2 - x, -surface.h / 2 - y, 0.0);
		viewMatrix.appendScale(zoom, zoom, 1.0);
		viewMatrix.appendRotation(0, Vector3D.Z_AXIS);

		var renderMatrixOrtho = new Matrix3D();
		renderMatrixOrtho.identity();
		renderMatrixOrtho.append(viewMatrix);
		renderMatrixOrtho.append(orthoProjectionMatrix);

		var renderMatrixPerspective = new Matrix3D();
		renderMatrixPerspective.identity();
		renderMatrixPerspective.append(viewMatrix);
		renderMatrixPerspective.append(perspectiveProjectionMatrix);

		return useOrthoMatrix ? renderMatrixOrtho : renderMatrixPerspective;
	}*/
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	public function drawNode(node:Node)
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
	
	public function drawGeometry(geometry:Geometry)
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
	
	//TODO only invoked when no effect available
	public function drawPrimitive()
	{
		var geometry = currGeometry;
		
		if (allowGlobalState)
			setGlobalState(geometry.states);
		
		if (allowTextures && currEffect != null)
			currTexture = currEffect.tex;
		
		drawElements();
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
		
		//convert transformation to 4x4 matrix
		getModelMatrix(spatial, currMVP);
		
		//concatenate with view and projection matrix
		currMVP.cat(currViewProjMatrix);
		
		return currMVP;
	}
	
	/**
	 * Computes the combined model-to-world matrix from <code>spatial</code>'s world transformation</code>
	 * and stores the result in <code>output</code>.
	 * @return a reference to <code>output</code>.
	 */
	public function getModelMatrix(spatial:Spatial, output:Mat44):Mat44
	{
		var xform = spatial.world;
		
		//#if debug
		//D.assert(!xform.isIdentity(), '!xform.isIdentity()');
		//#end
		
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
	
	/**
	 * Called whenever the viewport dimensions change.
	 */
	public function onViewPortChange() {}
	
	public function onFrustumChange()
	{
		if (_camera != null)
		{
			var f = _camera.frustum;
			
			//var t = makeOrtographicMatrix(0, RenderSurface.width, 0, RenderSurface.height);
			//var m = new Mat44();
			//m.ofMatrix3D(t);
			
			_projMatrix = new Mat44();
			//_projMatrix.setOrtho(f.left, f.right, f.bottom, f.top, f.near, f.far);
			_projMatrix.setOrthoSimple(RenderSurface.width, RenderSurface.height, 0, 1);
			
			//TODO why transpose?
			//var t = makeOrtographicMatrix(0, surface.w, 0, surface.h);
			//_projMatrix.ofVector(t.rawData);
			_projMatrix.transpose();
			
			//left-hand coordinates starting at the upper-right corner of the viewport
			
			//flip y-axis
			_projMatrix.catScale(1, -1, 1);
			
			//move to upper-right corner
			_projMatrix.catTranslate(-1, 1, 0);
			
			//_viewMatrix.setIdentity();
			//_viewMatrix.catScale(zoom, -zoom, 1); //flip y-axis
			//_viewMatrix.catRotateZ(rotation);
			
			//_viewMatrix.catTranslate(-surface.w / 2 - eyeX, surface.h/2, 0);
			//_viewMatrix.catTranslate(-surface.w / 2, -surface.h/2, 0);
		}
	}
	
	//TODO tmp
	#if flash
	/*function makeOrtographicMatrix(left:Float, right:Float, top:Float, bottom:Float, zNear:Float = 0, zFar:Float = 1):Matrix3D
	{
		return new Matrix3D(Vector.ofArray([
				2 / (right - left), 0, 0,  0,
				0,  2 / (top - bottom), 0, 0,
				0,  0, 1 / (zFar - zNear), 0,
				0, 0, zNear / (zNear - zFar), 1
			]));
	}*/
	#end
	
	public function onFrameChange()
	{
		var t = camera.local.getTranslate();
		
		//TODO rebuild matrix
		_viewMatrix.setIdentity();
		_viewMatrix.catScale(camera.zoom, camera.zoom, 1);
		
		_viewMatrix.catTranslate(t.x, t.y, 0);
	}
	
	public function drawDeferredRegular()
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
	
	public function drawDeferredBatch() {}

	//public function drawDisplayObject(effect:DisplayObjectEffect) {}
	
	public function drawEffect(effect:Effect)
	{
		if (allowGlobalState) setGlobalState(currGeometry.states);
	}
	
	public function drawTextureEffect(effect:TextureEffect)
	{
		if (allowGlobalState) setGlobalState(currGeometry.states);
	}
	
	public function drawSpriteSheetEffect(effect:SpriteSheetEffect)
	{
		if (allowGlobalState) setGlobalState(currGeometry.states);
	}
	
	//public function drawSpriteSheetBatchEffect(effect:SpriteSheetBatchEffect) {}
	
	//public function drawBitmapFont(effect:TextEffect) {}
	
	function drawElements() {}
	
	function onBeginScene() {}
	
	function onEndScene() {}
	
	function getType():Int
	{
		return throw 'override for implementation';
	}
}