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
import de.polygonal.core.math.Vec3;
import de.polygonal.motor.geom.inside.PointInsideAABB;
import de.polygonal.zz.scene.Geometry.VertexFormat;

/**
 * A quad face.
 */
class Quad extends TriMesh
{
	var _scratchVec3:Vec3;
	
	public function new(w = 1., h = 1., offset = 0.)
	{
		// 0      1
		// +------+
		// |013  /|
		// |    / |
		// |   /  |
		// |  /   |
		// | /    |
		// |/  123|
		// +------+
		// 3      2
		
		//TODO shared vertices and indices
		var key = Sprintf.format('%s.%s.%s', [offset, w, h]);
		//if (sharedVertices == null)
		//{
			var vertices =
			[
				new Vec3(0 + offset, 0 + offset),
				new Vec3(w + offset, 0 + offset),
				new Vec3(w + offset, h + offset),
				new Vec3(0 + offset, h + offset)
			];
			
			var indices = [0, 1, 3, 1, 2, 3];
		//}
		
		super(vertices, indices, false);
		
		type = GeometryType.QUAD;
		vertexFormat = VertexFormat.FLOAT2;
		
		_scratchVec3 = new Vec3();
		
		updateModelBound();
	}
	
	override public function pick(origin:Vec3, results:Array<Dynamic>):Int
	{
		var c = 0;
		if (worldBound.contains(origin))
		{
			var model = _scratchVec3;
			world.applyInverse2(origin, model);
			
			if (PointInsideAABB.test6(model.x, model.y, 0, 0, 1, 1)) //TODO take w and h into account
			{
				c++;
				if (results != null) results.push(this);
			}
		}
		return c;
	}
}