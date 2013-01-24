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
package de.polygonal.zz.render.effect;

import de.polygonal.core.fmt.ASCII;
import de.polygonal.core.math.Vec2;
import de.polygonal.ds.Bits;
import de.polygonal.ds.DA;
import de.polygonal.ds.pooling.DynamicObjectPool;
import de.polygonal.motor.geom.primitive.AABB2;
import de.polygonal.zz.render.texture.SpriteAtlas;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.render.texture.thirdparty.BMFontFormat;
import de.polygonal.zz.scene.Quad;
import de.polygonal.zz.scene.Renderer;

enum Align
{
	Center;
	Left;
	Right;
}

/**
 * Bitmap font based on the Angelcode bitmap font generator.
 * @see http://www.angelcode.com/products/bmfont/
 */
class TextEffect extends SpriteSheetEffect
{
	/**
	 * Defines the letter spacing.
	 */
	public var tracking = 0.;
	
	/**
	 * Defines line spacing.
	 */
	public var leading = .0;
	
	/**
	 * If false, ignores kerning.
	 */
	public var applyKerning = true;
	
	var _format:BMFontFormat;
	var _quadList:DA<FontQuad>;
	var _stringList:DA<StringBlock>;
	var _scratchQuad:Quad;
	var _nextCode:Int;
	var _fontQuadPool:DynamicObjectPool<FontQuad>;
	
	public function new(src:String, tex:Tex)
	{
		__textEffect = this;
		
		_format = new BMFontFormat(src);
		_quadList = new DA();
		_quadList.reuseIterator = true;
		_stringList = new DA();
		_scratchQuad = new Quad();
		_nextCode = -1;
		_fontQuadPool = new DynamicObjectPool(FontQuad);
		
		super(new SpriteAtlas(tex, _format));
	}
	
	override public function free():Void 
	{
		super.free();
		
		_format.free();
		_quadList.free();
		_stringList.free();
		_scratchQuad.free();
		_fontQuadPool.free();
		
		_format = null;
		_quadList = null;
		_stringList = null;
		_scratchQuad = null;
		_fontQuadPool = null;
	}
	
	public function setString(x:String, bound:AABB2, align:Align, size:Float):Int
	{
		if (_stringList.size() > 0)
		{
			updateString(0, x);
			return 0;
		}
		else
			return addString(x, bound, align, size);
	}
	
	public function addString(text:String, bound:AABB2, align:Align, size:Float):Int
	{
		var block = new StringBlock(text, bound, align, size, applyKerning);
		_stringList.pushBack(block);
		
		_quadList.concat(processQuads(block));
		
		return _stringList.size() - 1;
	}
	
	public function updateString(i:Int, text:String):Void
	{
		var b = _stringList.get(i);
		
		if (b.text == text) return;
		
		b.text = text;
		
		for (q in _quadList) _fontQuadPool.put(q);
		_quadList = processQuads(b);
	}
	
	/*public function clearString(i:Int):Void
	{
		_stringList.removeAt(i);
	}
	
	public function clearStrings():Void
	{
		_stringList.clear();
	}*/
	
	override public function draw(renderer:Renderer):Void
	{
		var node = renderer.currNode;
		
		var q = _scratchQuad;
		
		node.addChild(q);
		
		for (quad in _quadList)
		{
			var char = quad.bitmapChar;
			if (char.code == -1) continue;
			
			q.x = quad.x;
			q.y = quad.y;
			q.scaleX = char.w * quad.sizeScale;
			q.scaleY = char.h * quad.sizeScale;
			
			trace(char.w, char.h);
			
			q.updateGeometricState(true);
			
			this.frame = char.code;
			
			untyped renderer.currGeometry = q;
			untyped renderer.currEffect = this;
			
			renderer.drawSpriteSheetEffect(this);
		}
		
		node.removeChild(q);
	}
	
	function processQuads(b:StringBlock):DA<FontQuad>
	{
		var quads = new DA<FontQuad>();
		quads.reuseIterator = true;
		
		var x = b.bound.minX;
		var y = b.bound.minY;
		
		var lineWidth = 0.;
		var sizeScale = b.size / _format.charSet.renderedSize;
		
		var maxWidth = b.bound.intervalX;
		
		var lastCode = 0;
		var lineNumber = 1;
		var wordNumber = 1;
		var wordWidth = 0.;
		var firstCharOfLine = true;
		var text = b.text;
		
		var alignment = b.align;
		
		for (i in 0...text.length)
		{
			var code = text.charCodeAt(i);
			var char = text.charAt(i);
			
			var c = _format.charSet.characters[code];
			
			var xOffset = c.offX * sizeScale;
			var yOffset = c.offY * sizeScale;
			
			var stepX = c.stepX * sizeScale + tracking;
			var width = c.w * sizeScale;
			var height = c.h * sizeScale;
			
			if (y + yOffset + height > b.bound.maxY) break;
			
			if (code == ASCII.NEWLINE || code == ASCII.CARRIAGERETURN || (lineWidth + stepX >= maxWidth))
			{
				x =
				switch (alignment)
				{
					case Left:   b.bound.minX;
					case Right:  b.bound.minX + maxWidth * .5;
					case Center: b.bound.maxX;
				}
				y += (_format.charSet.lineHeight + leading) * sizeScale;
				
				var offset = 0.;
				
				if ((lineWidth + stepX >= maxWidth) && (wordNumber != 1))
				{
					var newLineLastChar = 0;
					lineWidth = 0.;
					
					for (q in quads)
					{
						switch (alignment)
						{
							case Left:
								if ((q.lineNumber == lineNumber) && (q.wordNumber == wordNumber))
								{
									q.lineNumber++;
									q.wordNumber = 1;
									q.x = x + (q.bitmapChar.offX * sizeScale);
									q.y = y + (q.bitmapChar.offY * sizeScale);
									x += q.bitmapChar.stepX * sizeScale;
									lineWidth += q.bitmapChar.stepX * sizeScale;
									if (b.kerning)
									{
										_nextCode = q.character;
										var key = Bits.packUI16(newLineLastChar, _nextCode);
										if (_format.charSet.kerning.exists(key))
										{
											var kerning = _format.charSet.kerning.get(key);
											x += kerning * sizeScale;
											lineWidth += kerning * sizeScale;
										}
									}
								}
							
							case Center:
								if ((q.lineNumber == lineNumber) && (q.wordNumber == wordNumber))
								{
									q.lineNumber++;
									q.wordNumber = 1;
									q.x = x + (q.bitmapChar.offX * sizeScale);
									q.y = y + (q.bitmapChar.offY * sizeScale);
									x += q.bitmapChar.stepX * sizeScale;
									lineWidth += q.bitmapChar.stepX * sizeScale;
									offset += q.bitmapChar.stepX * sizeScale * .5;
									if (b.kerning)
									{
										_nextCode = q.character;
										var key = Bits.packUI16(newLineLastChar, _nextCode);
										if (_format.charSet.kerning.exists(key))
										{
											var kerning = _format.charSet.kerning.get(key) * sizeScale;
											x += kerning;
											lineWidth += kerning;
											offset += kerning * .5;
										}
									}
								}
							
							case Right:
								if ((q.lineNumber == lineNumber) && (q.wordNumber == wordNumber))
								{
									q.lineNumber++;
									q.wordNumber = 1;
									q.x = x + (q.bitmapChar.offX * sizeScale);
									q.y = y + (q.bitmapChar.offY * sizeScale);
									lineWidth += q.bitmapChar.stepX * sizeScale;
									x += q.bitmapChar.stepX * sizeScale;
									offset += q.bitmapChar.stepX * sizeScale;
									if (b.kerning)
									{
										_nextCode = q.character;
										var key = Bits.packUI16(newLineLastChar, _nextCode);
										if (_format.charSet.kerning.exists(key))
										{
											var kerning = _format.charSet.kerning.get(key) * sizeScale;
											x += kerning;
											lineWidth += kerning;
											offset += kerning;
										}
									}
								}
						}
						newLineLastChar = q.character;
					}
					
					if (alignment == Center || alignment == Right)
					{
						for (q in quads)
							if (q.lineNumber == lineNumber + 1)
								q.x -= offset;
						
						x -= offset;
						
						for (q in quads)
							if (q.lineNumber == lineNumber)
								q.x += offset;
					}
				}
				else
				{
					firstCharOfLine = true;
					lineWidth = 0.;
				}
				
				wordNumber = 1;
				lineNumber++;
			}
			
			if (code == ASCII.NEWLINE || code == ASCII.CARRIAGERETURN || code == ASCII.TAB) continue;
			
			if (firstCharOfLine) 
			{
				x =
				switch (alignment) 
				{
					case Left:   b.bound.minX;
					case Center: b.bound.minX + (maxWidth * .5);
					case Right:  b.bound.maxX;
				}
			}
			
			var kernAmount = 0.;
			if (b.kerning && !firstCharOfLine)
			{
				_nextCode = text.charCodeAt(i);
				
				var key = Bits.packUI16(lastCode, _nextCode);
				if (_format.charSet.kerning.exists(key))
				{
					kernAmount = _format.charSet.kerning.get(key) * sizeScale;
					x += kernAmount;
					lineWidth += kernAmount;
					wordWidth += kernAmount;
				}
			}
			
			firstCharOfLine = false;
			
			var q = _fontQuadPool.get();
			
			var bound = q.bound;
			bound.minX = x + xOffset;
			bound.minY = y + yOffset;
			bound.maxX = bound.minX + width;
			bound.maxY = bound.minY + height;
			
			if (code == ASCII.SPACE && alignment == Right)
			{
				wordNumber++;
				wordWidth = 0.;
			}
			
			wordWidth += stepX;
			
			q.lineNumber = lineNumber;
			q.wordNumber = wordNumber;
			q.wordWidth  = wordWidth;
			q.bitmapChar = c;
			q.sizeScale  = sizeScale;
			q.character  = text.charCodeAt(i);
			
			quads.pushBack(q);
			
			if (code == ASCII.SPACE && alignment == Left)
			{
				wordNumber++;
				wordWidth = 0.;
			}
			
			x += stepX;
			lineWidth += stepX;
			lastCode = text.charCodeAt(i);
			
			switch (alignment)
			{
				case Center:
					var offset = stepX * .5;
					if (b.kerning) offset += kernAmount * .5;
					
					for (q in quads)
						if (q.lineNumber == lineNumber)
							q.x -= offset;
					x -= offset;
				
				case Right:
					var offset = 0.;
					if (b.kerning) offset += kernAmount;
					for (q in quads)
					{
						if (q.lineNumber == lineNumber)
						{
							offset = stepX;
							q.x -= stepX;
						}
					}
					x -= offset;
				
				default:
			}
		}
		
		return quads;
	}
}

private class StringBlock
{
	public var text:String;
	public var bound:AABB2;
	public var align:Align;
	public var size:Float;
	public var kerning:Bool;

	public function new(text:String, bound:AABB2, align:Align, size:Float, kerning:Bool)
	{
		this.text    = text;
		this.bound   = bound;
		this.align   = align;
		this.size    = size;
		this.kerning = kerning;
	}
}

private class FontQuad
{
	public var lineNumber:Int;
	public var wordNumber:Int;
	
	public var sizeScale:Float;
    public var bitmapChar:BitmapChar;
    public var character:Int;
    public var wordWidth:Float;
	
	public var bound:AABB2;
	
	public function new()
	{
		bound = new AABB2();
	}
	
	public var x(get_x, set_x):Float;
	inline function get_x():Float
	{
		return bound.minX;
	}
	inline function set_x(value:Float):Float
	{
		bound.setMinX(value);
		return value;
	}
	
	public var y(get_y, set_y):Float;
	inline function get_y():Float
	{
		return bound.minY;
	}
	inline function set_y(value:Float):Float
	{
		bound.setMinY(value);
		return value;
	}
}