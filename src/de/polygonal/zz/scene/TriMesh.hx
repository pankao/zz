package de.polygonal.zz.scene;

import de.polygonal.core.math.Vec3;
import de.polygonal.zz.scene.Geometry;
import de.polygonal.zz.scene.Triangles;

class TriMesh extends Triangles
{
	public function new(vertices:Array<Vec3>, indices:Array<Int>, generateVertexNormals:Bool)
	{
		super(GeometryType.TRIMESH);
		if (generateVertexNormals) generateNormals();
		
		this.vertices = vertices;
		this.indices = indices;
		
		/*if( idx == null ) {
			idx = new Array();
			for( i in 0...points.length )
				idx[i] = i;
		}*/
	}
		
	//TODO cache triangles
	
	inline override public function getNumTriangles():Int
	{
		return Std.int(indices.length / 3);
	}
	
	override public function getTriangle(i:Int):Triangle
	{
		var tri = null;
		
		//TODO reuse triangle object
		if (i >= 0 && i < getNumTriangles())
		{
			var offset = i * 3;
			
			var i0 = indices[offset + 0];
			var i1 = indices[offset + 1];
			var i2 = indices[offset + 2];
			
			tri = new Triangle();
			tri.v0 = vertices[tri.i0 = i0];
			tri.v1 = vertices[tri.i1 = i1];
			tri.v2 = vertices[tri.i2 = i2];
			
			tri.indices = [i0, i1, i2];
			tri.vertices = vertices;
		}
		
		return tri;
	}
	
	/*override public function getTriangles():Triangle
	{
		var triangleList = null;
		
		for (i in 0...getNumTriangles())
		{
			var offset = i * 3;
			var i0 = indices[offset + 0];
			var i1 = indices[offset + 1];
			var i2 = indices[offset + 2];
			var triangle = new Triangle(vertices[i0], vertices[i1], vertices[i2]);
			if (triangleList == null)
				triangleList = triangle
			else
				triangleList = triangle.next = triangle;
		}
		
		return triangleList;
	}*/
}