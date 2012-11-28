package de.polygonal.zz.scene;

import de.polygonal.core.math.Vec3;
import de.polygonal.zz.scene.Geometry;

class Triangles extends Geometry
{
	function new(type:Int, id:String = null)
	{
		super(type, id);
	}
	
	public function getNumTriangles():Int
	{
		return throw 'override for implementation';
	}
	
	public function getTriangle(i:Int):Triangle
	{
		return throw 'override for implementation';
	}
	
	public function updateModelNormals()
	{
		normals = new Array<Vec3>();
		
		for( i in 0...vertices.length)
			normals[i] = new Vec3();
		
		var iVQuantity = vertices.length;
		
		for (i in 0...getNumTriangles())
		{
			var triangle = getTriangle(i);
			
			// compute the normal (length provides the weighted sum)
			var edge1 = Vec3.sub(triangle.v1, triangle.v0, new Vec3());
			var edge2 = Vec3.sub(triangle.v2, triangle.v0, new Vec3());
			
			var normal = Vec3.cross(edge1, edge2, new Vec3());
			
			Vec3.add(normals[triangle.i0], normal, normals[triangle.i0]);
			Vec3.add(normals[triangle.i1], normal, normals[triangle.i1]);
			Vec3.add(normals[triangle.i2], normal, normals[triangle.i2]);
		}
		
		for (i in normals)
		{
			i.normalize();
		}
	}
	
	public function getModelTriangle(i:Int):Triangle
	{
		return getTriangle(i);
	}
	
	public function getWorldTriangle(i:Int):Triangle
	{
		var triangle = getTriangle(i);
		if (triangle != null)
		{
			triangle.v0 = world.applyForward(triangle.v0, new Vec3());
			triangle.v1 = world.applyForward(triangle.v1, new Vec3());
			triangle.v2 = world.applyForward(triangle.v2, new Vec3());
			return triangle;
		}
		return null;
	}
	
	public function generateNormals()
	{
		updateModelNormals();
	}
}