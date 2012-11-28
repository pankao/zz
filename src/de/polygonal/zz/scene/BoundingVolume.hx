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

import de.polygonal.core.math.Vec3;

class BoundingVolume
{
	inline public static var TYPE_SPHERE = 0;
	inline public static var TYPE_AABB   = 1;
	
	public var type:Int;
	public var sphereBV:SphereBV;
	
	public function new()
	{
		type = -1;
		sphereBV = null;
	}
	
	public function free()
	{
		sphereBV = null;
	}
	
	public function getCenter():Vec3
	{
		return null;
	}
	
	public function getRadius():Float
	{
		return 0;
	}
	
	public function setCenter(c:Vec3)
	{
	}
	
	public function setRadius(r:Float)
	{
	}
	
	public function growToContain(other:BoundingVolume)
	{
	}
	
	public function transformBy(transform:XForm, output:BoundingVolume)
	{
	}
	
	public function computeFromData(vertices:Array<Vec3>)
	{
	}
	
	public function set(other:BoundingVolume)
	{
	}
    
	public function testIntersectOther(other:BoundingVolume):Bool
	{
		return throw 'override for implementation';
	}
	
	public function testIntersectRay(origin:Vec3, direction:Vec3):Bool
	{
		return throw 'override for implementation';
	}
	
	public function contains(point:Vec3):Bool
	{
		return throw 'override for implementation';
	}
}