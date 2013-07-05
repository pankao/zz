package de.polygonal.zz.scene;

import de.polygonal.core.math.Vec3;
import de.polygonal.core.math.Mathematics;
import de.polygonal.core.util.Assert;

class Triangle
{
	static function ofFloatArray(vertices:Array<Float>):Array<Triangle>
	{
		#if debug
		D.assert(M.cmpZero(vertices.length / 9, M.EPS), 'M.cmpZero(vertices.length / 9, M.EPS)');
		#end
		
		var triangles = new Array<Triangle>();
		var i = 0;
		var k = vertices.length;
		while (i < k)
		{
			var tri = new Triangle();
			tri.v0 = new Vec3(vertices[i + 0], vertices[i + 1], vertices[i + 2]);
			tri.v1 = new Vec3(vertices[i + 3], vertices[i + 4], vertices[i + 5]);
			tri.v2 = new Vec3(vertices[i + 6], vertices[i + 7], vertices[i + 8]);
			triangles.push(tri);
			i += 9;
		}
		
		return triangles;
	}
	
	public var i0:Int;
	public var i1:Int;
	public var i2:Int;
	
	public var v0:Vec3;
	public var v1:Vec3;
	public var v2:Vec3;
	
	public var indices:Array<Int>;
	public var vertices:Array<Vec3>;
	
	public function new() {}
	
	public function toString():String
	{
		return Printf.format("{Triangle: indices=%d,%d,%d vertices=%s, %s, %s}", [i0, i1, i2, v0, v1, v2]);
	}
}