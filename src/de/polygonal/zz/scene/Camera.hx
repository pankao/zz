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

import de.polygonal.core.fmt.Sprintf;
import de.polygonal.core.math.Mat33;
import de.polygonal.core.math.Vec3;
import de.polygonal.ds.Bits;
import de.polygonal.zz.render.RenderSurface;
import de.polygonal.zz.scene.Renderer;
import de.polygonal.core.math.Mathematics;

using de.polygonal.ds.BitFlags;

class ViewFrustum
{
	public var left:Float;
	public var right:Float;
	
	public var top:Float;
	public var bottom:Float;
	
	public var near:Float;
	public var far:Float;
	
	public function new() {}
	
	public function toString():String
	{
		return Sprintf.format("{ViewFrustum: left=%.3f, right=%.3f, top=%.3f, bottom=%.3f, near=%.3f, far=%.3f}",
			[left, right, top, bottom, near, far]);
	}
	
	public function setOrtho(w:Int, h:Int):Void
	{
		left   = -w / 2;
		right  =  w / 2;
		top    =  h / 2;
		bottom = -h / 2;
		near   = 0;
		far    = 1;
	}
	
	public function getUpFovDegrees():Float
	{
		return 2 * Math.atan(top / near) * M.RAD_DEG;
	}

	public function getAspectRatio():Float
	{
		return right / top;
	}
	
	public function clone():ViewFrustum
	{
		var f = new ViewFrustum();
		f.left   = left;
		f.right  = right;
		f.top    = top;
		f.bottom = bottom;
		f.near   = near;
		f.far    = far;
		return f;
	}
}

//TODO bug in culling regarding flags?
//TODO additional culling planes

@:build(de.polygonal.core.util.IntEnum.build(
[
	BIT_PLANE_T,
	BIT_PLANE_R,
	BIT_PLANE_B,
	BIT_PLANE_L
], true))
class Camera extends Spatial
{
	public var planeCullState:Int;
	
	public var zoom:Float;
	
	/**
	 * The view frustum.
	 */
	public var frustum(default, null):ViewFrustum;
	
	var _renderer:Renderer;
	
	public function new()
	{
		super(null);
		
		frustum = new ViewFrustum();
		_renderer = null;
		
		setf(Spatial.BIT_IS_CAMERA);
		planeCullState = Bits.mask(4);
		
		zoom = 1;
	}
	
	override public function free()
	{
		super.free();
		frustum = null;
		_renderer = null;
	}
	
	
	
	public function setEye(location:Vec3)
	{
		local.setTranslate(location.x, location.y, location.z);
		
		if (_renderer != null)
			_renderer.onFrameChange();
	}
	
	public function setZoom(value:Float):Void
	{
		zoom = value;
		if (_renderer != null)
			_renderer.onFrameChange();
	}
	
	/**
	 * Specifies an orthographic view frustum.
	 */
	public function setFrustumOrtho(w:Int, h:Int)
	{
		frustum.setOrtho(w, h);
		if (_renderer != null) _renderer.onFrustumChange();
	}
	
	/**
	 * Compare world bound to view frustum.
	 * @return true if <code>bound</code> is outside the view <em>frustum</em>.
	 */
	public function isCulled(bound:BoundingVolume):Bool
	{
		var sphere = bound.sphereBV.sphere;
		var c = sphere.c;
		var r = sphere.r;
		/*var w = _renderer.window;
		
		if (planeCullState & BIT_PLANE_T > 0)
		{
			if (c.y < w.minY - r) return true;
			planeCullState &= ~BIT_PLANE_T;
		}
		
		if (planeCullState & BIT_PLANE_R > 0)
		{
			if (c.x > w.maxX + r) return true;
			planeCullState &= ~BIT_PLANE_R;
		}
		
		if (planeCullState & BIT_PLANE_B > 0)
		{
			if (c.y > w.maxY + r) return true;
			planeCullState &= ~BIT_PLANE_B;
		}
		
		if (planeCullState & BIT_PLANE_L > 0)
		{
			if (c.x < w.minX - r) return true;
			planeCullState &= ~BIT_PLANE_L;
		}*/
		
		var w = RenderSurface.width;
		var h = RenderSurface.height;
		
		if (planeCullState & BIT_PLANE_T > 0)
		{
			if (c.y < 0 - r) return true;
			planeCullState &= ~BIT_PLANE_T;
		}
		
		if (planeCullState & BIT_PLANE_R > 0)
		{
			if (c.x > w + r) return true;
			planeCullState &= ~BIT_PLANE_R;
		}
		
		if (planeCullState & BIT_PLANE_B > 0)
		{
			if (c.y > h + r) return true;
			planeCullState &= ~BIT_PLANE_B;
		}
		
		if (planeCullState & BIT_PLANE_L > 0)
		{
			if (c.x < 0 - r) return true;
			planeCullState &= ~BIT_PLANE_L;
		}
		
		return false;
	}
	
	/**
	 * Do nothing.
	 */
	override public function draw(renderer:Renderer, noCull:Bool) {}
	
	override private function _updateWorldData():Void
	{
		super._updateWorldData();
	}
	
	override function _updateWorldBound()
	{
		//the camera has an implicit model bound whose center is the camera's position and whose radius is zero.
		worldBound.setCenter(world.applyForward(local.getTranslate(), new Vec3()));
		worldBound.setRadius(0);
	}
}