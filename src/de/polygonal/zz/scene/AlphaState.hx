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
	public static var ADD_NO_ALPHA           = new AlphaState(SrcBlendFactor.One             , DstBlendFactor.One);
    public static var BLEND                  = new AlphaState(SrcBlendFactor.SourceAlpha     , DstBlendFactor.OneMinusSourceAlpha);
    public static var FILTER                 = new AlphaState(SrcBlendFactor.DestinationColor, DstBlendFactor.Zero);
    public static var MODULATE               = new AlphaState(SrcBlendFactor.DestinationColor, DstBlendFactor.Zero);
    public static var PREMULTIPLIED_ALPHA    = new AlphaState(SrcBlendFactor.One             , DstBlendFactor.OneMinusSourceAlpha);
    public static var NO_PREMULTIPLIED_ALPHA = new AlphaState(SrcBlendFactor.SourceAlpha     , DstBlendFactor.OneMinusSourceAlpha);
    public static var ADD                    = new AlphaState(SrcBlendFactor.SourceAlpha     , DstBlendFactor.One);
	
	public var src:SrcBlendFactor;
	public var dst:DstBlendFactor;
	
	public var key:Int;
	
	public function new(src:SrcBlendFactor = null, dst:DstBlendFactor = null)
	{
		super(GlobalStateType.Alpha);
		__alphaState = this;
		
		this.src = src == null ? SrcBlendFactor.SourceAlpha : src;
		this.dst = dst == null ? DstBlendFactor.OneMinusSourceAlpha : dst;
		
		key = (Type.enumIndex(src) + 1) << 16 | (Type.enumIndex(dst) + 1);
	}
	
	public function toString():String
	{
		return Sprintf.format("{AlphaState: src=%s, dst=%s}", [src, dst]);
	}
}