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
package de.polygonal.zz.render.module.flash.stage3d;

import de.polygonal.zz.render.module.flash.stage3d.Stage3DRenderer;
import de.polygonal.zz.render.texture.Image;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.core.math.Mathematics;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.utils.ByteArray;

class Stage3DTexture
{
	public var handle:flash.display3D.textures.Texture;
	public var image:Image;
	
	public var sourceTexture:Tex;
	
	public var atf:ByteArray;
	
	public var flags:Int;
	
	public function new(tex:Tex, flags = 0)
	{
		sourceTexture = tex;
		
		if (flags == 0) flags = Stage3DRenderer.DEFAULT_TEXTURE_FLAGS;
		this.flags = flags;
		
		handle = null;
		atf = null;
		
		//requires size to be a power of two
		//+========+     +========+====+
		//|        |     |        |    |
		//|        | ==> |        |    |
		//+========+     +========+    |
		//               |             |
		//               |             |
		//               +=============+
		var srcImage = sourceTexture.image;
		var srcW = srcImage.w;
		var srcH = srcImage.h;
		var newW = M.nextPow2(srcW);
		var newH = M.nextPow2(srcH);
		
		///TODO check if power of two
		
		var data = new BitmapData(newW, newH, true, 0);
		data.copyPixels(srcImage.data, srcImage.data.rect, new Point());
		image = new Image(data, newW, newH);
	}
	
	public function free():Void
	{
		trace('free Stage3DTexture [' + sourceTexture.key + ']');
		
		if (handle != null)
		{
			try { handle.dispose(); } catch (error:Dynamic) {}
			handle = null;
		}
		
		image.free();
		image = null;
		sourceTexture = null;
		atf = null;
	}
	
	public function upload(context:Context3D):Void
	{
		if (handle != null) return;
		
		handle = context.createTexture(image.w, image.h, Context3DTextureFormat.BGRA, false, 0);
		
		if (atf != null)
		{
			var textureFormat = (atf[6] == 2 ? Context3DTextureFormat.COMPRESSED : Context3DTextureFormat.BGRA);
			handle = context.createTexture(Std.int(Math.pow(2, atf[7])), Std.int(Math.pow(2, atf[8])), textureFormat, false);
			handle.uploadCompressedTextureFromByteArray(atf, 0, false);
			return;
		}
		
		if (image == null) return;
		
		//handle mip mapping
		if (flags & (Stage3DTextureFlag.MM_LINEAR | Stage3DTextureFlag.MM_NEAREST) > 0)
		{
			var ws = image.w;
			var hs = image.h;
			var level = 0;
			var tmp = new BitmapData(ws, hs, true, 0);
			var transform = new Matrix();
			while (ws >= 1 || hs >= 1)
			{
				tmp.fillRect(tmp.rect, 0);
				tmp.draw(image.data, transform, null, null, null, true);
				handle.uploadFromBitmapData(tmp, level);
				transform.scale(.5, .5);
				level++;
				ws >>= 1;
				hs >>= 1;
			}
			tmp.dispose();
		}
		else
			handle.uploadFromBitmapData(image.data, 0);
	}
}