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

import de.polygonal.core.math.Vec2;
import de.polygonal.core.math.Vec3;
import de.polygonal.motor.geom.bv.MinimumAreaCircle;
import de.polygonal.motor.geom.inside.PointInsideSphere;
import de.polygonal.motor.geom.primitive.Sphere2;

class SphereBV extends BoundingVolume
{
	public var sphere(default, null):Sphere2;
	
	var _c:Vec2;
	var _center:Vec3;
	
	var _scratchVec31:Vec3;
	var _scratchVec32:Vec3;
	
	public function new()
	{
		super();
		
		type = BoundingVolume.TYPE_SPHERE;
		
		sphereBV = this;
		
		sphere = new Sphere2();
		_c = sphere.c;
		_center = new Vec3();
		
		_scratchVec31 = new Vec3();
		_scratchVec32 = new Vec3();
	}
	
	override public function free():Void
	{
		sphere = null;
		_c = null;
		_center = null;
	}
	
	inline override public function getCenter():Vec3
	{
		_center.x = _c.x;
		_center.y = _c.y;
		return _center;
	}
	
	inline override public function getRadius():Float
	{
		return sphere.r;
	}
	
	inline override public function setCenter(c:Vec3):Void
	{
		_c.x = c.x;
		_c.y = c.y;
	}
	
	inline override public function setRadius(r:Float):Void
	{
		sphere.r = r;
	}
	
	override public function computeFromData(vertices:Array<Vec3>):Void
	{
		var tmp = [];
		var i = 0;
		var k = vertices.length;
		while (i < k)
		{
			tmp.push(new Vec2(vertices[i].x, vertices[i].y));
			i++;
		}
		MinimumAreaCircle.findExact(tmp, sphere);
	}
	
	override public function growToContain(other:BoundingVolume):Void
	{
		sphere.addSphere(other.sphereBV.sphere);
	}
	
	override public function contains(point:Vec3):Bool
	{
		return PointInsideSphere.test5(point.x, point.y, sphere.c.x, sphere.c.y, sphere.r);
	}
	
	override public function transformBy(transform:XForm, output:BoundingVolume):Void
	{
		//var c = transform.timesVector(new Vec3(sphere.c.x, sphere.c.y));
		//var r = sphere.r * world.RSNorm();
		//result.sphere.c.x = c.x;
		//result.sphere.c.y = c.y;
		//result.sphere.r   = r;
		
		/*var t = new Vec3();
		transform.applyForward(new Vec3(sphere.c.x, sphere.c.y), t);
		
		var out = output.sphereBV;
		out.sphere.c.x = t.x;
		out.sphere.c.y = t.y;
		out.sphere.r   = transform.getNorm() * sphere.r;*/
		
		
		var t1 = _scratchVec31;
		var t2 = _scratchVec32;
		t2.x = sphere.c.x;
		t2.y = sphere.c.y;
		
		transform.applyForward(t2, t1);
		
		var out = output.sphereBV;
		out.sphere.c.x = t1.x;
		out.sphere.c.y = t1.y;
		out.sphere.r   = transform.getNorm() * sphere.r;
	}
	
	override public function set(other:BoundingVolume):Void
	{
		sphere.set(other.sphereBV.sphere);
	}
}