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
 * 
 * 
 * Based on Wm3Transformation class from the Wild Magic Library (WM3)
 * Geometric Tools, Inc.
 * http://www.geometrictools.com
 * Copyright (c) 1998-2006.  All Rights Reserved
 * 
 * The Wild Magic Library (WM3) source code is supplied under the terms of
 * the license agreement
 *     http://www.geometrictools.com/License/WildMagic3License.pdf
 * and may not be copied or disclosed except in accordance with the terms
 * of that agreement. 
 */
package de.polygonal.zz.scene;

import de.polygonal.core.math.Mat33;
import de.polygonal.core.math.Mathematics;
import de.polygonal.core.math.Vec3;
import de.polygonal.ds.Bits;
import de.polygonal.core.util.Assert;

using de.polygonal.ds.BitFlags;

/**
 * <p>Represents an affine transformation Y = M*X+T where M is a 3x3 matrix and T is a translation vector.</p>
 * <ul>
 * <li>The vector X is transformed in the "forward" direction to Y.</li>
 * <li>The "inverse" direction transforms Y to X (X = M^{-1}*(Y-T) in the general case).</li>
 * <li>When M = R*S, the inverse direction is X = S^{-1}*R^t*(Y-T).</li>
 * <li>In most cases, M = R, a rotation matrix, or M = R*S where R is a rotation matrix and S is a diagonal matrix whose diagonal entries are positive scales.</li>
 * </p>
 */
@:build(de.polygonal.core.util.IntEnum.build(
[
	BIT_HINT_IDENTITY,
	BIT_HINT_RS_MATRIX,
	BIT_HINT_UNIFORM_SCALE,
	BIT_HINT_UNIT_SCALE
], true))
class XForm
{
	static var _sharedScratchMatrix1:Mat33;
	static var _sharedScratchMatrix2:Mat33;
	
	var _scale:Vec3;
	var _translate:Vec3;
	var _matrix:Mat33;
	var _scratchMatrix1:Mat33;
	var _scratchMatrix2:Mat33;
	var _bits:Int;
	
	public function new()
	{
		_scale = new Vec3();
		_translate = new Vec3();
		_matrix = new Mat33();
		
		if (_sharedScratchMatrix1 == null)
		{
			_sharedScratchMatrix1 = new Mat33();
			_sharedScratchMatrix2 = new Mat33();
		}
		
		_scratchMatrix1 = _sharedScratchMatrix1;
		_scratchMatrix2 = _sharedScratchMatrix2;
		
		setIdentity();
	}
	
	public function free():Void
	{
		_scale = null;
		_translate = null;
		_matrix = null;
		_scratchMatrix1 = null;
		_scratchMatrix2 = null;
	}
	
	inline public function isIdentity():Bool
	{
		return hasf(BIT_HINT_IDENTITY);
	}
	
	inline public function isRSMatrix():Bool
	{
		return hasf(BIT_HINT_RS_MATRIX);
	}
	
	inline public function isUniformScale():Bool
	{
		return hasf(BIT_HINT_UNIFORM_SCALE);
	}
	
	inline public function isUnitScale():Bool
	{
		return hasf(BIT_HINT_UNIT_SCALE);
	}
	
	inline public function getScale():Vec3
	{
		#if debug
		D.assert(isRSMatrix());
		#end
		
		return _scale;
	}
	
	inline public function getTranslate():Vec3
	{
		return _translate;
	}
	
	inline public function getRotate():Mat33
	{
		#if debug
		D.assert(isRSMatrix());
		#end
		
		return _matrix;
	}
	
	inline public function getMatrix():Mat33
	{
		return _matrix;
	}
	
	inline public function getUniformScale():Float
	{
		#if debug
		D.assert(incf(BIT_HINT_RS_MATRIX | BIT_HINT_UNIFORM_SCALE));
		#end
		
		return _scale.x;
	}
	
	inline public function setIdentity():Void
	{
		_matrix.setIdentity();
		_translate.zero();
		_scale.x = 1;
		_scale.y = 1;
		_scale.z = 1;
		setf(BIT_HINT_IDENTITY | BIT_HINT_RS_MATRIX | BIT_HINT_UNIFORM_SCALE | BIT_HINT_UNIT_SCALE);
	}
	
	inline public function setIdentity2():Void
	{
		var m = _matrix;
		m.m11 = 1; m.m12 = 0;
		m.m21 = 0; m.m22 = 1;
		_translate.x = 0;
		_translate.y = 0;
		_scale.x = 1;
		_scale.y = 1;
		setf(BIT_HINT_IDENTITY | BIT_HINT_RS_MATRIX | BIT_HINT_UNIFORM_SCALE | BIT_HINT_UNIT_SCALE);
	}
	
	inline public function setScale(x:Float, y:Float, z:Float):XForm
	{
		#if debug
		D.assert(isRSMatrix());
		D.assert(x != 0 && y != 0 && z != 0);
		#end
		
		_scale.x = x;
		_scale.y = y;
		_scale.z = z;
		clrf(BIT_HINT_IDENTITY | BIT_HINT_UNIFORM_SCALE | BIT_HINT_UNIT_SCALE);
		return this;
	}
	
	inline public function setScale2(x:Float, y:Float):XForm
	{
		#if debug
		D.assert(isRSMatrix());
		D.assert(x != 0 && y != 0);
		#end
		
		_scale.x = x;
		_scale.y = y;
		clrf(BIT_HINT_IDENTITY | BIT_HINT_UNIFORM_SCALE | BIT_HINT_UNIT_SCALE);
		return this;
	}
	
	inline public function setUniformScale(x:Float):XForm
	{
		#if debug
		D.assert(x != 0);
		D.assert(isRSMatrix());
		#end
		
		_scale.x = x;
		_scale.y = x;
		_scale.z = x;
		clrf(BIT_HINT_IDENTITY);
		setf(BIT_HINT_UNIFORM_SCALE);
		setfif(BIT_HINT_UNIT_SCALE, x == 1);
		return this;
	}
	
	inline public function setUniformScale2(x:Float):XForm
	{
		#if debug
		D.assert(x != 0);
		D.assert(isRSMatrix());
		#end
		
		_scale.x = x;
		_scale.y = x;
		clrf(BIT_HINT_IDENTITY | BIT_HINT_UNIT_SCALE);
		setf(BIT_HINT_UNIFORM_SCALE);
		setfif(BIT_HINT_UNIT_SCALE, x == 1);
		return this;
	}
	
	inline public function setUnitScale():XForm
	{
		#if debug
		D.assert(hasf(BIT_HINT_RS_MATRIX));
		#end
		
		_scale.x = 1;
		_scale.y = 1;
		_scale.z = 1;
		clrf(BIT_HINT_IDENTITY);
		setf(BIT_HINT_UNIFORM_SCALE | BIT_HINT_UNIT_SCALE);
		return this;
	}
	
	inline public function setUnitScale2():XForm
	{
		#if debug
		D.assert(hasf(BIT_HINT_RS_MATRIX));
		#end
		
		_scale.x = 1;
		_scale.y = 1;
		clrf(BIT_HINT_IDENTITY);
		setf(BIT_HINT_UNIFORM_SCALE | BIT_HINT_UNIT_SCALE);
		return this;
	}
	
	inline public function setTranslate(x:Float, y:Float, z:Float):XForm
	{
		_translate.x = x;
		_translate.y = y;
		_translate.z = z;
		clrf(BIT_HINT_IDENTITY);
		return this;
	}
	
	inline public function setTranslate2(x:Float, y:Float):XForm
	{
		_translate.x = x;
		_translate.y = y;
		clrf(BIT_HINT_IDENTITY);
		return this;
	}
	
	inline public function setRotate(x:Mat33):XForm
	{
		_matrix.set(x);
		clrf(BIT_HINT_IDENTITY);
		setf(BIT_HINT_RS_MATRIX);
		return this;
	}
	
	inline public function setRotate2(x:Mat33):XForm
	{
		var m = _matrix;
		m.m11 = x.m11; m.m12 = x.m12;
		m.m21 = x.m21; m.m22 = x.m22;
		clrf(BIT_HINT_IDENTITY);
		setf(BIT_HINT_RS_MATRIX);
		return this;
	}
	
	inline public function setMatrix(x:Mat33):XForm
	{
		_matrix.set(x);
		clrf(BIT_HINT_IDENTITY | BIT_HINT_RS_MATRIX | BIT_HINT_UNIFORM_SCALE | BIT_HINT_UNIT_SCALE);
		return this;
	}
	
	inline public function setMatrix2(x:Mat33):XForm
	{
		var m = _matrix;
		m.m11 = x.m11; m.m12 = x.m12;
		m.m21 = x.m21; m.m22 = x.m22;
		clrf(BIT_HINT_IDENTITY | BIT_HINT_RS_MATRIX | BIT_HINT_UNIFORM_SCALE | BIT_HINT_UNIT_SCALE);
		return this;
	}
	
	inline public function set(other:XForm):XForm
	{
		_translate.set(other._translate);
		_scale.set(other._scale);
		_matrix.set(other._matrix);
		cpyf(other);
		return this;
	}
	
	inline public function set2(other:XForm):XForm
	{
		var t = other._translate;
		_translate.x = t.x;
		_translate.y = t.y;
		t = other._scale;
		_scale.x = t.x;
		_scale.y = t.y;
		var t = other._matrix;
		var m = _matrix;
		m.m11 = t.m11; m.m12 = t.m12;
		m.m21 = t.m21; m.m22 = t.m22;
		cpyf(other);
		return this;
	}
	
	/**
	 * Computes Y = M*X+T where X is = <code>input</code> and Y = <code>output</code>.
	 */
	public function applyForward(input:Vec3, output:Vec3):Vec3
	{
		if (isIdentity())
		{
			//Y = X
			output.set(input);
		}
		else
		if (isRSMatrix())
		{
			if (isUnitScale())
			{
				//Y = R*X + T
				output.x = input.x;
				output.y = input.y;
				output.z = input.z;
			}
			else
			{
				//Y = R*S*X + T
				var t = _scale;
				output.x = input.x * t.x;
				output.y = input.y * t.y;
				output.z = input.z * t.z;
			}
			
			_matrix.timesVector(output);
			var t = _translate;
			output.x += t.x;
			output.y += t.y;
			output.z += t.z;
			
		}
		else
		{
			//Y = M*X + T
			output.set(input);
			_matrix.timesVector(output);
			var t = _translate;
			output.x += t.x;
			output.y += t.y;
			output.z += t.z;
		}
		
		return output;
	}
	
	/**
	 * Computes Y = M*X+T where X is = <code>input</code> and Y = <code>output</code>.<br/>
	 * <warn>In constrast to <em>applyForward()</em>, this method operates in 2d space and ignores <code>input</code>.z.</warn>
	 */
	inline public function applyForward2(input:Vec3, output:Vec3):Vec3
	{
		if (isIdentity())
		{
			//Y = X
			output.x = input.x;
			output.y = input.y;
		}
		else
		if (isRSMatrix())
		{
			if (isUnitScale())
			{
				//Y = R*X + T
				var m = _matrix;
				var x = input.x;
				var y = input.y;
				output.x = (m.m11 * x + m.m12 * y) + _translate.x;
				output.y = (m.m21 * x + m.m22 * y) + _translate.y;
			}
			else
			{
				//Y = R*S*X + T
				var x = input.x * _scale.x;
				var y = input.y * _scale.y;
				var m = _matrix;
				output.x = (m.m11 * x + m.m12 * y) + _translate.x;
				output.y = (m.m21 * x + m.m22 * y) + _translate.y;
			}
		}
		else
		{
			//Y = M*X + T
			var x = input.x;
			var y = input.y;
			var m = _matrix;
			output.x = (m.m11 * x + m.m12 * y) + _translate.x;
			output.y = (m.m21 * x + m.m22 * y) + _translate.y;
		}
		
		return output;
	}
	
	/**
	 * Computes X = M^{-1}*(Y-T) where Y = <code>input</code> and X = <code>output</code>.<br/>
	 * The parameters <code>input</code> and <code>output</code> can point to the same object.
	 */
	public function applyInverse(input:Vec3, output:Vec3):Vec3
	{
		if (isIdentity())
		{
			//X = Y
			output.set(input);
		}
		else
		{
			var t = _translate;
			output.x = input.x - t.x;
			output.y = input.y - t.y;
			output.z = input.z - t.z;
			
			if (isRSMatrix())
			{
				//X = S^{-1}*R^t*(Y - T)
				_matrix.vectorTimes(output);
				if (isUniformScale())
					output.scale(1 / getUniformScale());
				else
				{
					t = _scale;
					output.x /= t.x;
					output.y /= t.y;
					output.z /= t.z;
				}
			}
			else
			{
				//X = M^{-1}*(Y - T)
				_matrix.inverseConst(_scratchMatrix1);
				_scratchMatrix1.timesVector(output);
			}
		}
		
		return output;
	}
	
	/**
	 * Computes X = M^{-1}*(Y-T) where Y = <code>input</code> and X = <code>output</code>.<br/>
	 * The parameters <code>input</code> and <code>output</code> can point to the same object.<br/>
	 * <warn>In contrast to <em>applyInverse()</em>, this method operates in 2d space and ignores <code>input</code>.z.</warn>
	 */
	public function applyInverse2(input:Vec3, output:Vec3):Vec3
	{
		if (isIdentity())
		{
			//X = Y
			output.x = input.x;
			output.y = input.y;
		}
		else
		{
			var t = _translate;
			var x = input.x - t.x;
			var y = input.y - t.y;
			
			if (isRSMatrix())
			{
				//X = S^{-1}*R^t*(Y - T)
				//_matrix.vectorTimes(output);
				var m = _matrix;
				output.x = (x * m.m11 + y * m.m21) / _scale.x;
				output.y = (x * m.m12 + y * m.m22) / _scale.y;
			}
			else
			{
				//X = M^{-1}*(Y - T)
				var m = _matrix;
				var t11 = m.m11; var t12 = m.m12;
				var t21 = m.m21; var t22 = m.m22;
				var det = t11 * t22 - t12 * t21;
				if (Mathematics.fabs(det) > Mathematics.ZERO_TOLERANCE)
				{
					var invDet = 1 / det;
					var x = output.x;
					var y = output.y;
					output.x = ( t22 * invDet) * x + (-t12 * invDet) * y;
					output.y = (-t21 * invDet) * x + ( t11 * invDet) * y;
				}
				else
					output.x = output.y = 0;
			}
		}
		
		return output;
	}
	
	/**
	 * Computes this = <code>a</code> * <code>b</code> and returns this.
	 * @throws de.polygonal.AssertError <code>a</code> equals <code>b</code> (debug only).
	 */
	public function product(a:XForm, b:XForm):XForm
	{
		#if debug
		D.assert(a != b, 'a != b');
		#end
		
		//|rA*sA|tA|  |rB*sB|tB|  |rA*sA*rB*sB|rA*sA*tB+tA|
		//|  0^t| 1|  |  0^t| 1|  |        0^t|          1|
		if (a.isIdentity()) return set(b);
		if (b.isIdentity()) return set(a);
		
		//both transformations are M = R*S, so matrix can be written as R*S*X + T
		if (a.incf(BIT_HINT_RS_MATRIX | BIT_HINT_UNIFORM_SCALE) && b.isRSMatrix())
		{
			//rotation: rA * rB
			Mat33.matrixProduct(a._matrix, b._matrix, _matrix);
			
			//translation: sA * (rA*tB) + tA
			var tc = _translate;
			var ta = a._translate;
			
			var sa = a.getUniformScale();
			
			a._matrix.timesVectorConst(b._translate, tc);
			
			tc.x = tc.x * sa + ta.x;
			tc.y = tc.y * sa + ta.y;
			tc.z = tc.z * sa + ta.z;
			
			//scale: sA * sB
			if (b.isUniformScale())
			{
				//setUniformScale(sa * b.getUniformScale());
				sa *= b.getUniformScale();
				_scale.x = sa;
				_scale.y = sa;
				_scale.z = sa;
				clrf(BIT_HINT_IDENTITY);
				setf(BIT_HINT_UNIFORM_SCALE | BIT_HINT_RS_MATRIX);
				setfif(BIT_HINT_UNIT_SCALE, sa == 1);
			}
			else
			{
				//setScale(sa * sb.x, sa * sb.y, sa * sb.z);
				var sb = b._scale;
				_scale.x = sa * sb.x;
				_scale.y = sa * sb.y;
				_scale.z = sa * sb.z;
				clrf(BIT_HINT_IDENTITY | BIT_HINT_UNIFORM_SCALE | BIT_HINT_UNIT_SCALE);
				setf(BIT_HINT_RS_MATRIX);
			}
			
			return this;
		}
		
		var ma = (a.isRSMatrix()) ? (a._matrix.timesDiagonalConst(a._scale, _scratchMatrix1)) : a._matrix;
		var mb = (b.isRSMatrix()) ? (b._matrix.timesDiagonalConst(b._scale, _scratchMatrix2)) : b._matrix;
		
		Mat33.matrixProduct(ma, mb, _matrix);
		
		var t = _translate;
		var ta = a._translate;
		ma.timesVectorConst(b._translate, t);
		t.x += ta.x;
		t.y += ta.y;
		t.z += ta.z;
		
		clrf(BIT_HINT_IDENTITY | BIT_HINT_RS_MATRIX | BIT_HINT_UNIFORM_SCALE | BIT_HINT_UNIT_SCALE);
		return this;
	}
	
	/**
	 * Computes <code>this</code> = <code>a</code> * <code>b</code> and returns this.
	 * <warn>In contrast to <em>product()</em>, this method operates in 2d space.
	 * @throws de.polygonal.AssertError <code>a</code> equals <code>b</code> (debug only).
	 */
	public function product2(a:XForm, b:XForm):XForm
	{
		#if debug
		D.assert(a != b, 'a != b');
		#end
		
		//|rA*sA|tA|  |rB*sB|tB|  |rA*sA*rB*sB|rA*sA*tB+tA|
		//|  0^t| 1|  |  0^t| 1|  |        0^t|          1|
		if (a.isIdentity()) return set(b);
		if (b.isIdentity()) return set(a);
		
		//both transformations are M = R*S, so matrix can be written as R*S*X + T
		if (a.incf(BIT_HINT_RS_MATRIX | BIT_HINT_UNIFORM_SCALE) && b.isRSMatrix())
		{
			//rotation: rA * rB
			var ma = a._matrix;
			var mb = b._matrix;
			var mc = _matrix;
			var b11 = mb.m11; var b12 = mb.m12;
			var b21 = mb.m21; var b22 = mb.m22;
			var t1, t2;
			t1 = ma.m11;
			t2 = ma.m12;
			mc.m11 = t1 * b11 + t2 * b21;
			mc.m12 = t1 * b12 + t2 * b22;
			t1 = ma.m21;
			t2 = ma.m22;
			mc.m21 = t1 * b11 + t2 * b21;
			mc.m22 = t1 * b12 + t2 * b22;
			t1 = ma.m31;
			t2 = ma.m32;
			mc.m31 = t1 * b11 + t2 * b21;
			mc.m32 = t1 * b12 + t2 * b22;
			
			//translation: sA * (rA*tB) + tA
			var ta = a._translate;
			var tb = b._translate;
			var tc = _translate;
			var x = tb.x;
			var y = tb.y;
			tc.x = ma.m11 * x + ma.m12 * y;
			tc.y = ma.m21 * x + ma.m22 * y;
			
			var sa = a.getUniformScale();
			tc.x = tc.x * sa + ta.x;
			tc.y = tc.y * sa + ta.y;
			
			//scale: sA * sB
			if (b.isUniformScale())
			{
				//setUniformScale(sa * b.getUniformScale());
				sa *= b.getUniformScale();
				_scale.x = sa;
				_scale.y = sa;
				
				clrf(BIT_HINT_IDENTITY);
				setf(BIT_HINT_UNIFORM_SCALE | BIT_HINT_RS_MATRIX);
				setfif(BIT_HINT_UNIT_SCALE, sa == 1);
			}
			else
			{
				//setScale(sa * sb.x, sa * sb.y, sa * sb.z);
				var sb = b._scale;
				_scale.x = sa * sb.x;
				_scale.y = sa * sb.y;
				clrf(BIT_HINT_IDENTITY | BIT_HINT_UNIFORM_SCALE | BIT_HINT_UNIT_SCALE);
				setf(BIT_HINT_RS_MATRIX);
			}
			
			return this;
		}
		
		var ma = a._matrix;
		var mb = b._matrix;
		
		if (a.isRSMatrix())
		{
			var sx = a._scale.x;
			var sy = a._scale.y;
			var m = _scratchMatrix1;
			m.m11 = ma.m11 * sx; m.m12 = ma.m12 * sy;
			m.m21 = ma.m21 * sx; m.m22 = ma.m22 * sy;
			ma = m;
		}
		
		if (b.isRSMatrix())
		{
			var sx = b._scale.x;
			var sy = b._scale.y;
			var m = _scratchMatrix2;
			m.m11 = mb.m11 * sx; m.m12 = mb.m12 * sy;
			m.m21 = mb.m21 * sx; m.m22 = mb.m22 * sy;
			mb = m;
		}
		
		var b11 = mb.m11; var b12 = mb.m12;
		var b21 = mb.m21; var b22 = mb.m22;
		var mc = _matrix;
		var t1, t2;
		t1 = ma.m11;
		t2 = ma.m12;
		mc.m11 = t1 * b11 + t2 * b21;
		mc.m12 = t1 * b12 + t2 * b22;
		t1 = ma.m21;
		t2 = ma.m22;
		mc.m21 = t1 * b11 + t2 * b21;
		mc.m22 = t1 * b12 + t2 * b22;
		
		var t = _translate;
		var ta = a._translate;
		var tb = b._translate;
		
		var x = tb.x;
		var y = tb.y;
		t.x = (ma.m11 * x + ma.m12 * y) + ta.x;
		t.y = (ma.m21 * x + ma.m22 * y) + ta.y;
		
		clrf(BIT_HINT_IDENTITY | BIT_HINT_RS_MATRIX | BIT_HINT_UNIFORM_SCALE | BIT_HINT_UNIT_SCALE);
		return this;
	}
	
	/**
	 * Computes the inverse-transform of <code>input</code>, which is <code>output</code> = M^{-1}*<code>input</code>.<br/>
	 * The parameters <code>input</code> and <code>output</code> can point to the same object.
	 */
	public function invertVector(input:Vec3, output:Vec3):Vec3
	{
		if (isIdentity())
		{
			//X = Y
			output.set(input);
		}
		if (isRSMatrix())
		{
			//X = S^{-1}*R^t*Y
			output.set(input);
			_matrix.vectorTimes(output);
			if (isUniformScale())
				output.scale(1 / getUniformScale());
			else
			{
				var s = _scale;
				output.x /= s.x;
				output.y /= s.y;
				output.z /= s.z;
			}
		}
		else
		{
			//X = M^{-1}*Y
			_matrix.inverseConst(_scratchMatrix1);
			_scratchMatrix1.timesVector(output);
		}
		
		return output;
	}
	
	/**
	 * Computes the inverse-transform of <code>input</code>, which is <code>output</code> = M^{-1}*<code>input</code>.<br/>
	 * The parameters <code>input</code> and <code>output</code> can point to the same object.<br/>
	 * <warn>In contrast to <em>invertVector<()/em>, this method operates in 2d space and ignores <code>input</code>.z</warn>
	 */
	public function invertVector2(input:Vec3, output:Vec3):Vec3
	{
		if (isIdentity())
		{
			//X = Y
			output.x = input.x;
			output.y = input.y;
		}
		if (isRSMatrix())
		{
			//X = S^{-1}*R^t*Y
			var x = input.x;
			var y = input.y;
			var t = x;
			var m = _matrix;
			x = x * m.m11 + y * m.m21;
			y = t * m.m12 + y * m.m22;
			
			if (isUniformScale())
			{
				var s = getUniformScale();
				output.x = x / s;
				output.y = y / s;
				
			}
			else
			{
				var s = _scale;
				output.x = x / s.x;
				output.y = y / s.y;
			}
		}
		else
		{
			//X = M^{-1}*Y
			var m = _matrix;
			var det = m.m11 * m.m22 - m.m12 * m.m21;
			if (M.fabs(det) > M.ZERO_TOLERANCE)
			{
				var invDet = 1 / det;
				output.x =  (m.m22 * invDet) * input.x + (-m.m12 * invDet) * input.y;
				output.y = (-m.m21 * invDet) * input.x +  (m.m11 * invDet) * input.y;
			}
			else
			{
				output.x = 0;
				output.y = 0;
			}
		}
		
		return output;
	}
	
	/**
	 * Computes the inverse transformation, stores the result in <code>output</code> and returns <code>output</code>.<br/>
	 * If &lt;M,T&gt; is the matrix-translation pair, the inverse is &lt;M^{-1},-M^{-1}*T&gt;.
	 */
	public function inverse(output:XForm):XForm
	{
		if (isIdentity())
			return output.set(this);
		
		if (isRSMatrix())
		{
			if (isUniformScale())
			{
				_matrix.transposeConst(output._matrix);
				output._matrix.timesScalar(1 / getUniformScale());
			}
			else
			{
				_matrix.timesDiagonalConst(_scale, output._matrix);
				output._matrix.inverse();
			}
		}
		else
			_matrix.inverseConst(output._matrix);
		
		output._matrix.timesVectorConst(_translate, output._translate);
		output._translate.flip();
		output.nulf();
		return output;
	}
	
	/**
	 * For M = R*S, returns the largest absolute value of S.<br/>
	 * For general M, the max-column-sum norm is returned and is guaranteed to be larger than or equal to the largest eigenvalue of S in absolute value.
	 */
	public function getNorm():Float
	{
		if (isRSMatrix())
		{
			//return largest absolute value of S
			var max = Mathematics.fabs(_scale.x);
			if (Mathematics.fabs(_scale.y) > max) max = Mathematics.fabs(_scale.y);
			if (Mathematics.fabs(_scale.z) > max) max = Mathematics.fabs(_scale.z);
			return max;
		}
		else
		{
			//return max-column-sum norm (guaranteed to be >= than the largest absolute eigenvalue of S
			return _matrix.norm();
		}
	}
	
	/**
	 * Same as <em>getNorm()</em>, but operates in 2d space.
	 */
	public function getNorm2():Float
	{
		if (isRSMatrix())
		{
			//return largest absolute value of S
			var max = Mathematics.fabs(_scale.x);
			if (Mathematics.fabs(_scale.y) > max) max = Mathematics.fabs(_scale.y);
			return max;
		}
		else
		{
			//return max-column-sum norm (guaranteed to be >= than the largest absolute eigenvalue of S
			var m = _matrix;
			var maxColSum = Mathematics.fabs(m.m11) + Mathematics.fabs(m.m21);
			var colSum    = Mathematics.fabs(m.m12) + Mathematics.fabs(m.m22);
			if (colSum > maxColSum) maxColSum = colSum;
			return maxColSum;
		}
	}
}