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
package de.polygonal.zz.render.module.flash.misc;

import de.polygonal.core.math.Vec2;
import de.polygonal.core.math.Vec3;
import de.polygonal.ds.HashMap;
import de.polygonal.gl.text.VectorFont;
import de.polygonal.gl.VectorRenderer;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.texture.Image;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.scene.Node;
import de.polygonal.zz.scene.Renderer;
import de.polygonal.zz.scene.Spatial;
import de.polygonal.zz.scene.SphereBV;
import de.polygonal.zz.render.RenderSurface;
import flash.display.Graphics;

class GraphicsRenderer extends Renderer
{
	public static var ZERO = new Vec3();
	
	public var drawNames = false;
	public var drawParentLinks = true;
	public var drawTriangles = true;
	public var drawBounds = true;
	public var drawOrigin = true;
	
	var _vr:VectorRenderer;
	var _font:VectorFont;
	var _nullEffect:Effect;
	var _effectStash:de.polygonal.ds.HashMap<Spatial, Effect>;
	
	var _scratchVec3:Vec3;
	
	var _graphics:Graphics;
	
	public function new(width = 0, height = 0)
	{
		super(width, height);
		
		drawDeferred = null;
		
		_graphics = RenderSurface.root.graphics;
		
		noCulling = true;
		
		_vr = new VectorRenderer();
		_font = new de.polygonal.gl.text.fonts.rondaseven.PFRondaSeven();
		_font.setRenderer(_vr);
		_nullEffect = new Effect();
		_effectStash = new HashMap();
		
		_scratchVec3 = new Vec3();
	}
	
	override public function drawScene(scene:Node)
	{
		for (i in scene.treeNode)
		{
			if (i.effect != null) _effectStash.set(i, i.effect);
			if (i.isNode())
			{
				//assign a do-nothing effect to invoke drawNode() and drawElements()
				i.effect = _nullEffect;
			}
			else
			if (i.isGeometry())
			{
				//use drawElements()
				i.effect = null;
			}
		}
		
		super.drawScene(scene);
	}
	
	override public function createTex(image:Image):Tex
	{
		var tex = super.createTex(image);
		if (tex == null)
		{
			tex = new Tex(image, false, false);
			_textureLookup.set(image.key, tex);
		}
		return tex;
	}
	
	override public function drawNode(node:Node)
	{
		//child->parent relationship
		if (drawParentLinks) drawParent(node);
		
		//world position
		if (drawOrigin)
		{
			var origin = toScreen(node, ZERO);
			drawMarker(origin.x, origin.y, 3, 0xff0000);
		}
		
		//world bounding volume
		if (drawBounds)
		{
			//bounding sphere position => screen space
			var sphere = cast(node.worldBound, SphereBV).sphere;
			drawCircle(sphere.c.x, sphere.c.y, sphere.r * 1.02, 0xff0000);
		}
		
		//id
		if (drawNames && node.id != null)
		{
			var origin = toScreen(node, ZERO);
			drawLabel(origin.x + 10, origin.y, 0xff0000, node.id);
		}
		
		//default drawNode() implementation skips children, so force drawing them now
		var c = node.treeNode.children;
		while (c != null)
		{
			c.val.cull(this, noCulling);
			c = c.next;
		}
	}
	
	override function drawElements()
	{
		var g = currGeometry;
		
		//child->parent relationship
		if (drawParentLinks) drawParent(g);
		
		//world position
		if (drawOrigin)
		{
			var origin = toScreen(g, ZERO);
			drawSolidBox(origin.x, origin.y, 2, 0x0000ff);
		}
		
		//world bounding volume
		if (drawBounds)
		{
			var sphere = cast(g.worldBound, SphereBV).sphere;
			var center = worldToScreen(new Vec3(sphere.c.x, sphere.c.y));
			var radius = worldToScreen(new Vec3(sphere.r, 0, 0, 1)).x;
			drawCircle(center.x, center.y, radius, 0x0000ff);
		}
		
		//world triangles
		if (drawTriangles)
		{
			var v = new Array<Vec3>();
			
			var src = g.vertices;
			var i = 0;
			var k = src.length;
			//while (i < k) v.push(toScreen(g, new Vec3(src[i++], src[i++], src[i++])));
			//while (i < k) v.push(toScreen(g, new Vec3(src[i++], src[i++]))); //TODO 2d or 3d
			while (i < k) v.push(toScreen(g, src[i++])); //TODO 2d or 3d
			
			var indices = g.indices;
			var i = 0;
			var k = indices.length;
			while (i < k)
			{
				var a = v[indices[i++]];
				var b = v[indices[i++]];
				var c = v[indices[i++]];
				drawTriangle(a, b, c, 0);
			}
		}
		
		//id
		if (drawNames && g.id != null)
		{
			var origin = toScreen(g, ZERO);
			drawLabel(origin.x + 10, origin.y, 0x0000ff, g.id);
		}
	}
	
	override function onEndScene()
	{
		//restore effects
		for (i in currScene.treeNode)
		{
			if (_effectStash.hasKey(i))
				i.effect = _effectStash.get(i);
			else
				i.effect = null;
		}
		
		_effectStash.clear();
		
		_vr.setLineStyle(0, 1, 0);
		_vr.aabb(RenderSurface.bound);
		
		_vr.flush(_graphics);
	}
	
	function toScreen(spatial:Spatial, x:Vec3):Vec3
	{
		//local space -> world space
		var w = spatial.world.applyForward(x, new Vec3());
		
		//world space -> clip space
		var c = currViewProjMatrix.timesVectorConst(w, new Vec3());
		
		//clip space -> screen space
		var bound = RenderSurface.bound;
		var x = (c.x + 1) * bound.centerX + bound.minX;
		var y = (1 - c.y) * bound.centerY + bound.minY;
		
		return new Vec3(x, y);
	}
	
	function worldToScreen(input:Vec3):Vec2
	{
		//world space -> clip space
		currViewProjMatrix.timesVectorConst(input, _scratchVec3);
		
		//clip space -> screen space
		var bound = RenderSurface.bound;
		var x = (_scratchVec3.x + 1) * bound.centerX + bound.minX;
		var y = (1 - _scratchVec3.y) * bound.centerY + bound.minY;
		return new Vec2(x, y);
	}
	
	function drawParent(node:Spatial)
	{
		var parent = node.treeNode.parent;
		if (parent != null)
		{
			var origin = toScreen(node, ZERO);
			var originParent = toScreen(parent.val, ZERO);
			var dx = origin.x - originParent.x;
			var dy = origin.y - originParent.y;
			var dist = Math.sqrt(dx * dx + dy * dy);
			if (dist < 10) return;
			dx /= dist;
			dy /= dist;
			origin.x -= dx * 5;
			origin.y -= dy * 5;
			originParent.x += dx * 5;
			originParent.y += dy * 5;
			_vr.setLineStyle(0x000000, .25);
			_vr.arrowLine5(origin.x, origin.y, originParent.x, originParent.y, 3);
		}
	}
	
	function drawCircle(x:Float, y:Float, r:Float, color:Int)
	{
		_vr.setLineStyle(color, .75);
		_vr.circle3(x, y, r);
	}
	
	function drawMarker(x:Float, y:Float, r:Float, color:Int)
	{
		_vr.setLineStyle(color, 1, 0);
		_vr.crossSkewed3(x, y, r);
	}
	
	function drawSolidBox(x:Float, y:Float, r:Float, color:Int)
	{
		_vr.clearStroke();
		_vr.setFillColor(color, 1);
		_vr.fillStart();
		_vr.box3(x, y, r);
		_vr.fillEnd();
	}
	
	function drawSolidCircle(x:Float, y:Float, r:Float, color:Int)
	{
		_vr.clearStroke();
		_vr.setFillColor(color, 1);
		_vr.fillStart();
		_vr.circle3(x, y, r);
		_vr.fillEnd();
	}
	
	function drawTriangle(a:Vec3, b:Vec3, c:Vec3, color:Int)
	{
		_vr.setLineStyle(color, .75);
		_vr.moveTo2(a.x, a.y);
		_vr.lineTo2(b.x, b.y);
		_vr.lineTo2(c.x, c.y);
		_vr.lineTo2(a.x, a.y);
	}
	
	function drawLabel(x:Float, y:Float, color:Int, text:String)
	{
		_vr.clearStroke();
		_vr.setFillColor(color, 1);
		_vr.fillStart();
		_font.write(text, cast x, cast y);
		_vr.fillEnd();
	}
}