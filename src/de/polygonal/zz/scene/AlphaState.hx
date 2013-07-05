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

enum SrcBlendFactor
{
	Zero;
	One;
	DestinationColor;
	OneMinusDestinationColor;
	SourceAlpha;
	OneMinusSourceAlpha;
	DestinationAlpha;
	OneMinusDestinationAlpha;
}

enum DstBlendFactor
{
	Zero;
	One;
	SourceColor;
	OneMinusSourceColor;
	SourceAlpha;
	OneMinusSourceAlpha;
	DestinationAlpha;
	OneMinusDestinationAlpha;
}

class AlphaState extends GlobalState
{
	public static var NONE         = new AlphaState(SrcBlendFactor.One             , DstBlendFactor.Zero);
	
	public static var BLEND        = new AlphaState(SrcBlendFactor.SourceAlpha     , DstBlendFactor.OneMinusSourceAlpha);
	public static var ADD          = new AlphaState(SrcBlendFactor.SourceAlpha     , DstBlendFactor.DestinationAlpha);
	public static var MULTIPLY     = new AlphaState(SrcBlendFactor.DestinationColor, DstBlendFactor.Zero);
	public static var SCREEN       = new AlphaState(SrcBlendFactor.SourceAlpha     , DstBlendFactor.One);
	
	public static var BLEND_PMA    = new AlphaState(SrcBlendFactor.One             , DstBlendFactor.OneMinusSourceAlpha);
	public static var ADD_PMA      = new AlphaState(SrcBlendFactor.One             , DstBlendFactor.One);
	public static var MULTIPLY_PMA = new AlphaState(SrcBlendFactor.DestinationColor, DstBlendFactor.OneMinusSourceAlpha);
	public static var SCREEN_PMA   = new AlphaState(SrcBlendFactor.One             , DstBlendFactor.OneMinusSourceColor);
	
	public var src:SrcBlendFactor;
	public var dst:DstBlendFactor;
	
	public function new(src:SrcBlendFactor, dst:DstBlendFactor)
	{
		super(GlobalStateType.Alpha);
		__alphaState = this;
		
		this.src = src;
		this.dst = dst;
		
		var shiftOffset = Type.getEnumConstructs(GlobalStateType).length;
		flags |= 1 << (Type.enumIndex(src) + shiftOffset);
		flags |= 1 << (Type.enumIndex(dst) + shiftOffset + 8);
	}
	
	public function toString():String
		return Printf.format("{AlphaState: src=%s, dst=%s}", [src, dst]);
}