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
import de.polygonal.motor.geom.primitive.AABB2;
import de.polygonal.zz.render.texture.SpriteAtlas;
import de.polygonal.zz.render.texture.SpriteSheet;
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
	var _quads:Array<FontQuad>;
	
	var strings:DA<StringBlock>;
	
	var _format:BMFontFormat;
	var _scratchQuad:Quad;
	var _nextCode:Int;
	
	public function new(src:String, tex:Tex)
	{
		__textEffect = this;
		
		_format = new BMFontFormat(src);
		
		_scratchQuad = new Quad();
		
		_nextCode = -1;
		
		strings = new DA();
		_quads = [];
		
		super(new SpriteAtlas(tex, _format));
	}
	
	public function setText(x:String, bound:AABB2, align:Align, size:Float):Void
	{
		if (strings.size() > 0)
			updateString(0, x);
		else
			addString(x, bound, align, size, 0, true);
	}
	
	override public function draw(renderer:Renderer):Void
	{
		var node = renderer.currNode;
		
		var q = _scratchQuad;
		
		node.addChild(q);
		
		for (quad in _quads)
		{
			var char = quad.bitmapChar;
			if (char.code == -1) continue;
			
			q.x = quad.X;
			q.y = quad.Y;
			q.scaleX = char.w * quad.sizeScale;
			q.scaleY = char.h * quad.sizeScale;
			
			q.updateGeometricState(true);
			
			this.frame = char.code;
			
			untyped renderer.currGeometry = q;
			untyped renderer.currEffect = this;
			
			renderer.drawSpriteSheetEffect(this);
		}
		
		node.removeChild(q);
	}
	
	public function updateString(i:Int, text:String):Void
	{
		var b = strings.get(i);
		b.text = text;
		_quads = processQuads(b);
	}
	
	public function addString(text:String, bound:AABB2, align:Align, size:Float, color:Int, applyKerning:Bool):Int
	{
		var block = new StringBlock(text, bound, align, size, color, applyKerning);
		strings.pushBack(block);
		
		var index = strings.size() - 1;
		
		_quads = processQuads(block);
		
		/*for (quad in _quads)
		{
			var b = new AABB2();
			b.minX = quad.TopLeft.x;
			b.minY = quad.TopLeft.y;
			
			b.maxX = quad.BottomRight.x;
			b.maxY = quad.BottomRight.y;
			
			vr.setLineStyle(0xFF8000, 1, 0);
			vr.aabb(b);
		}*/
		
		_quads = _quads.concat(_quads);
		
		return index;
	}
	
	
	public function clearString(i:Int):Void
	{
		strings.removeAt(i);
	}
	
	public function clearStrings():Void
	{
		strings.clear();
	}
	
	function processQuads(b:StringBlock):Array<FontQuad>
	{
		var quads = new Array<FontQuad>();
		
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
			
			var stepX = c.stepX * sizeScale;
			var width = c.w * sizeScale;
			var height = c.h * sizeScale;
			
			if (y + yOffset + height > b.bound.maxY) break;
			
			if (code == ASCII.NEWLINE || code == ASCII.CARRIAGERETURN || (lineWidth + stepX >= maxWidth))
			{
				x = 
				switch (alignment) 
				{
					case Left:   b.bound.minX;
					case Right:  b.bound.minX + maxWidth / 2;
					case Center: b.bound.maxX;
				}
				y += _format.charSet.lineHeight * sizeScale;
				
				var offset = .0;
				
				if ((lineWidth + stepX >= maxWidth) && (wordNumber != 1))
				{
					var newLineLastChar = 0;
					lineWidth = .0;
					
					for (j in 0...quads.length)
					{
						var q = quads[j];
						
						switch (alignment) 
						{
							case Left:
								if ((q.lineNumber == lineNumber) && (q.wordNumber == wordNumber))
								{
									q.lineNumber++;
									q.wordNumber = 1;
									q.X = x + (q.bitmapChar.offX * sizeScale);
									q.Y = y + (q.bitmapChar.offY * sizeScale);
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
									q.X = x + (q.bitmapChar.offX * sizeScale);
									q.Y = y + (q.bitmapChar.offY * sizeScale);
									x += q.bitmapChar.stepX * sizeScale;
									lineWidth += q.bitmapChar.stepX * sizeScale;
									offset += q.bitmapChar.stepX * sizeScale / 2;
									if (b.kerning)
									{
										_nextCode = q.character;
										var key = Bits.packUI16(newLineLastChar, _nextCode);
										if (_format.charSet.kerning.exists(key))
										{
											var kerning = _format.charSet.kerning.get(key) * sizeScale;
											x += kerning;
											lineWidth += kerning;
											offset += kerning / 2;
										}
									}
								}
							
							case Right:
								if ((q.lineNumber == lineNumber) && (q.wordNumber == wordNumber))
								{
									q.lineNumber++;
									q.wordNumber = 1;
									q.X = x + (q.bitmapChar.offX * sizeScale);
									q.Y = y + (q.bitmapChar.offY * sizeScale);
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
						for (k in 0...quads.length)
						{
							if (quads[k].lineNumber == lineNumber + 1)
								quads[k].X -= offset;
						}
						x -= offset;
						
						for (k in 0...quads.length)
						{
							if (quads[k].lineNumber == lineNumber)
								quads[k].X += offset;
						}
					}
				}
				else
				{
					firstCharOfLine = true;
					lineWidth = .0;
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
					case Center: b.bound.minX + ( maxWidth / 2);
					case Right:  b.bound.maxX;
				}
			}
			
			var kernAmount = .0;
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
			
			var topLeft = new Vec2(x + xOffset, y + yOffset);
			//var u = c.x / _charSet.textureW;
			//var v = c.y / _charSet.textureH;
			
			var topRight = new Vec2( topLeft.x + width, y + yOffset);
			//var u = (c.x + c.w) / _charSet.textureW;
			//var v = c.y / _charSet.textureH;
			
			var bottomRight = new Vec2( topLeft.x + width, topLeft.y + height);
			//var u = (c.x + c.w) / _charSet.textureW;
			//var v = (c.y + c.h) / _charSet.textureH;
			
			var bottomLeft = new Vec2(x + xOffset, topLeft.y + height);
			//var u = c.x / _charSet.textureW;
			//var v = (c.y + c.h) / _charSet.textureH;
			
			var q = new FontQuad();
			q.TopLeft = topLeft;
			q.TopRight = topRight;
			q.BottomLeft = bottomLeft;
			q.BottomRight = bottomRight;
			q.lineNumber = lineNumber;
			
			if (code == ASCII.SPACE && alignment == Right)
			{
				wordNumber++;
				wordWidth = .0;
			}
			q.wordNumber = wordNumber;
			wordWidth += stepX;
			q.wordWidth = wordWidth;
			q.bitmapChar = c;
			q.sizeScale = sizeScale;
			q.character = text.charCodeAt(i);
			quads.push(q);

			if (code == ASCII.SPACE && alignment == Left)
			{
				wordNumber++;
				wordWidth = .0;
			}
			
			x += stepX;
			lineWidth += stepX;
			lastCode = text.charCodeAt(i);
			
			switch (alignment) 
			{
				case Center:
					var offset = stepX / 2;
					if (b.kerning) offset += kernAmount / 2;
					for (j in 0...quads.length)
					{
						var q = quads[j];
						if (q.lineNumber == lineNumber) q.X -= offset;
					}
					x -= offset;
					
				case Right:
					var offset = .0;
					if (b.kerning) offset += kernAmount;
					for (j in 0...quads.length)
					{
						var q = quads[j];
						if (q.lineNumber == lineNumber)
						{
							offset = stepX;
							q.X -= stepX;
						}
					}
					x -= offset;
					
				default:
			}
		}
		
		return quads;
	}
}

class StringBlock
{
	public var text:String;
	public var bound:AABB2;
	public var align:Align;
	public var size:Float;
	public var color:Int;
	public var kerning:Bool;

	public function new(text:String, bound:AABB2, align:Align, size:Float, color:Int, kerning:Bool)
	{
		this.text    = text;
		this.bound   = bound;
		this.align   = align;
		this.size    = size;
		this.color   = color;
		this.kerning = kerning;
	}
}


class FontQuad
{
	public var lineNumber:Int;
	public var wordNumber:Int;
	
	public var sizeScale:Float;
    public var bitmapChar:BitmapChar;
    public var character:Int;
    public var wordWidth:Float;
	
	public var TopLeft:Vec2;
	public var TopRight:Vec2;
	public var BottomLeft:Vec2;
	public var BottomRight:Vec2;
	
	public function new()
	{
	}
	
	public var X(get_X, set_X):Float;
	function get_X():Float
	{
		return TopLeft.x;
	}
	function set_X(value:Float):Float
	{
		var width = Width;
		TopLeft.x = value;
		BottomRight.x = value + width;
		BottomLeft.x = value;
		TopLeft.x = value;
		TopRight.x = value + width;
		BottomRight.x = value + width;
		return value;
	}
	
	public var Y(get_Y, set_Y):Float;
	function get_Y():Float
	{
		return TopLeft.y;
	}
	function set_Y(value:Float):Float
	{
		var height = Height;
        TopLeft.y = value;
        BottomRight.y = value + height;
        BottomLeft.y = value + height;
        TopLeft.y = value;
        TopRight.y = value;
        BottomRight.y = value + height;
		return value;
	}
	
	public var Width(get_Width, set_Width):Float;
	function get_Width():Float
	{
		return TopRight.x - TopLeft.x;
	}
	function set_Width(value:Float):Float
	{
		BottomRight.x = TopLeft.x + value;
		TopRight.x = TopLeft.x + value;
		BottomRight.x = TopLeft.x + value;
		return value;
	}
	
	public var Height(get_Height, set_Height):Float;
	function get_Height():Float
	{
		return BottomLeft.y - TopLeft.y;
	}
	function set_Height(value:Float):Float
	{
		BottomRight.y = TopLeft.y + value;
		BottomLeft.y  = TopLeft.y + value;
		BottomRight.y = TopLeft.y + value;
		return value;
	}
	
	public var Right(get_Right, never):Float;
	function get_Right():Float
	{
		return return X + Width;
	}
	
	public var Bottom(get_Bottom, never):Float;
	function get_Bottom():Float
	{
		return return Y + Height;
	}
}