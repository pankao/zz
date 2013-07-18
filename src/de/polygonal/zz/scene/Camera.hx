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

import de.polygonal.core.math.Mat33;
import de.polygonal.core.math.TrigApprox;
import de.polygonal.core.math.Vec2;
import de.polygonal.core.math.Vec3;
import de.polygonal.ds.Bits;
import de.polygonal.zz.render.RenderSurface;
import de.polygonal.core.math.Mathematics;

using de.polygonal.ds.BitFlags;

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
	
	var _renderer:Renderer;
	var _scratchVec:Vec3;
	
	public function new()
	{
		super('Camera');
		
		planeCullState = Bits.mask(4);
		zoom = 1;
		
		_scratchVec = new Vec3();
	}
	
	override public function free():Void
	{
		super.free();
		_renderer = null;
	}
	
	public function setRenderer(renderer:Renderer):Void
	{
		_renderer = renderer;
		
		//x = -renderer.width / 2;
		//y = -renderer.height / 2;
		
		_renderer.onFrameChange();
	}
	
	public function invalidate():Void
	{
		
	}
	
	public function setFrame(location:Vec3, direction:Vec3, up:Vec3, right:Vec3):Void
	{
		local.setTranslate(location.x, location.y, location.y);
		local.setRotate(new Mat33().setCols(direction, up, right));
		//onFrameChange();
	}
	
	public function setLocation(location:Vec3):Void
	{
		local.setTranslate(location.x, location.y, location.z);
		if (_renderer != null)
			_renderer.onFrameChange();
	}
	
	public function setZoom(value:Float):Void
	{
		zoom = value;
		
		scaleX = zoom;
		scaleY = zoom;
		
		local.setUniformScale2(zoom);
		
		if (_renderer != null)
			_renderer.onFrameChange();
	}
	
	public function setRotation(value:Float):Void
	{
		rotation = value;
		if (_renderer != null)
			_renderer.onFrameChange();
	}
	
	/**
	 * Compare world bound to view frustum.
	 * @return true if <code>bound</code> is outside the view <em>frustum</em>.
	 */
	public function isCulled(bound:BoundingVolume):Bool
	{
		var sphere = bound.__sphereBV.sphere;
		var c = sphere.c;
		var r = sphere.r;
		
		var w = _renderer.width;
		var h = _renderer.height;
		
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
	override public function draw(renderer:Renderer, noCull:Bool):Void
	{
	}
	
	override function updateWorldBound():Void
	{
		//the camera has an implicit model bound whose center is the camera's position and whose radius is zero.
		worldBound.setCenter(world.applyForward(local.getTranslate(), _scratchVec));
		worldBound.setRadius(0);
	}
	
	override function updateWorldData(updateBV:Bool):Void
	{
		super.updateWorldData(false);
		_renderer.onFrameChange();
	}
	
	override function syncLocalXForm2d():Void
	{
		if (scaleX == scaleY)
			local.setUniformScale2(scaleX);
		else
			local.setScale2(scaleX, scaleY);
		
		var r = local.getRotate();
		var sineCosine = TrigApprox.sinCos(rotation, r.sineCosine);
		var s = sineCosine.x;
		var c = sineCosine.y;
		r.m11 = c; r.m12 =-s;
		r.m21 = s; r.m22 = c;
		
		local.setTranslate2(x, y);
	}
	
	override function syncLocalXForm3d():Void
	{
	}
}