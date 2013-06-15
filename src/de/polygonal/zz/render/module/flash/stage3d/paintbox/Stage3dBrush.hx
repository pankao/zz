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
package de.polygonal.zz.render.module.flash.stage3d.paintbox;

import de.polygonal.core.fmt.Sprintf;
import de.polygonal.core.math.Vec3;
import de.polygonal.core.util.ClassUtil;
import de.polygonal.ds.DA;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.module.flash.stage3d.shader.AgalShader;
import de.polygonal.zz.render.module.flash.stage3d.Stage3dRenderer;
import de.polygonal.zz.render.module.flash.stage3d.Stage3dTextureFlag;
import de.polygonal.zz.scene.Geometry;
import flash.display3D.Context3D;
import flash.Vector;

class Stage3dBrush
{
	var _context:Context3D;
	var _vb:Stage3dVertexBuffer;
	var _ib:Stage3dIndexBuffer;
	var _shader:AgalShader;
	
	var _batch:DA<Geometry>;
	var _batchCapacity:Int;
	var _scratchVector:Vector<Float>;
	var _scratchVec3:Vec3;
	
	function new(context:Context3D, effectFlags:Int, textureFlags:Int)
	{
		_context = context;
		
		_batch = new DA();
		_batchCapacity = -1;
		_scratchVector = new flash.Vector<Float>();
		_scratchVec3 = new Vec3();
		
		L.d(Sprintf.format('create brush: %-40s effects: %-30s texture flags: %s',
			[ClassUtil.getUnqualifiedClassName(Type.getClass(this)), Effect.print(effectFlags), Stage3dTextureFlag.print(textureFlags)]), 's3d');
	}
	
	public function free():Void
	{
		if (_vb != null) _vb.free();
		if (_ib != null) _ib.free();
		
		_batch.clear(true);
		_batch = null;
		
		if (_shader != null) _shader.free();
		_shader = null;
	}
	
	public function draw(renderer:Stage3dRenderer):Void
	{
		//bind vertex buffer & program if changed
		var t = renderer.currBrush;
		if (t != this)
		{
			if (t != null) t._vb.unbind();
			_vb.bind();
			_shader.bindProgram();
		}
		renderer.currBrush = this;
		
		//bind texture if changed
		var t0 = renderer.prevStage3dTexture;
		var t1 = renderer.currStage3dTexture;
		if (t0 != t1) _shader.bindTexture(0, t1 == null ? null : t1.handle);
		renderer.prevStage3dTexture = t1;
	}
	
	inline public function add(x:Geometry):Void
	{
		_batch.pushBack(x);
	}
	
	inline public function isFull():Bool
	{
		return _batch.size() == _batchCapacity;
	}
	
	inline public function isEmpty():Bool
	{
		return _batch.isEmpty();
	}
}