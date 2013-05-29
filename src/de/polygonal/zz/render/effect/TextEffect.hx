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
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.render.texture.thirdparty.BMFontFormat;
import de.polygonal.zz.scene.Geometry;
import de.polygonal.zz.scene.Quad;
import de.polygonal.zz.scene.Renderer;
import de.polygonal.zz.scene.Node;

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
	public static var id:Int = 0;
	
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
	
	public var monoSpaceWidth = -1;
	
	var _format:BMFontFormat;
	var _stringList:DA<StringBlock>;
	var _nextCode:Int;
	
	var _quads:Array<FontQuad>;
	var _invalidate:Bool;
	var _lastBound:AABB2;
	
	var _numQuads:Int;
	
	public function new(format:BMFontFormat, tex:Tex)
	{
		TextEffect.id++;
		
		__textEffect = this;
		
		_format = format;
		_stringList = new DA<StringBlock>();
		_nextCode = -1;
		
		super(new SpriteAtlas(tex, _format));
		
		_numQuads = 0;
		_quads = [];
	}
	
	override public function free():Void
	{
		super.free();
		
		_format = null;
		_stringList.free();
		
		for (i in _quads) i.free();
		_quads = null;
		
		_format = null;
		_stringList = null;
	}
	
	public function setString(x:String, bound:AABB2, align:Align, size:Float):Void
	{
		if (bound == null)
			bound = _lastBound;
		
		if (_stringList.size() > 0)
			updateString(0, x);
		else
		{
			addString(x, bound, align, size);
			_lastBound = bound;
		}
	}
	
	public function addString(text:String, bound:AABB2, align:Align, size:Float):Int
	{
		var block = new StringBlock(text, bound, align, size, applyKerning);
		_stringList.pushBack(block);
		
		_numQuads = processQuads(block);
		_invalidate = true;
		
		return _stringList.size() - 1;
	}
	
	public function updateString(i:Int, text:String, align:Align = null):Void
	{
		var block = _stringList.get(i);
		if (block.text == text && block.align == align) return;
		
		if (align != null) block.align = align;
		block.text = text;
		_numQuads = processQuads(block);
		_invalidate = true;
	}
	
	override public function draw(renderer:Renderer):Void
	{
		var node = renderer.currNode;
		
		//add/remove children, update geometry
		if (_invalidate)
		{
			_invalidate = false;
			
			for (i in 0..._quads.length)
				node.removeChild(_quads[i]);
				
			for (i in 0..._numQuads)
			{
				var fq = _quads[i];
				var c = fq.bitmapChar;
				if (c.code == -1) continue;
				
				node.addChild(fq);
				
				fq.x = fq.minX;
				fq.y = fq.minY;
				fq.scaleX = c.w * fq.sizeScale;
				fq.scaleY = c.h * fq.sizeScale;
				fq.effect.__spriteSheetEffect.frame = c.code;
			}
			
			node.updateGeometricState();
			node.updateRenderState();
		}
		
		for (i in 0..._numQuads)
		{
			var fq = _quads[i];
			fq.effect.alpha = alpha;
		}
		
		//temporarily disable effect in order to draw child nodes
		var tmp = node.effect;
		node.effect = null;
		node.draw(renderer, renderer.noCulling);
		
		//restore effect
		node.effect = tmp;
	}
	
	function processQuads(b:StringBlock):Int
	{
		var quads = _quads;
		var numQuads = 0;
		
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
			var stepX = (monoSpaceWidth == -1 ? c.stepX : monoSpaceWidth) * sizeScale + tracking;
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
					
					for (i in 0...numQuads)
					{
						var q = quads[i];
						var bc = q.bitmapChar;
						switch (alignment)
						{
							case Left:
								if ((q.lineNumber == lineNumber) && (q.wordNumber == wordNumber))
								{
									q.lineNumber++;
									q.wordNumber = 1;
									q.minX = x + (bc.offX * sizeScale);
									q.minY = y + (bc.offY * sizeScale);
									x += bc.stepX * sizeScale;
									lineWidth += bc.stepX * sizeScale;
									
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
									q.minX = x + (bc.offX * sizeScale);
									q.minY = y + (bc.offY * sizeScale);
									x += bc.stepX * sizeScale;
									lineWidth += bc.stepX * sizeScale;
									offset += bc.stepX * sizeScale * .5;
									
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
									q.minX = x + (bc.offX * sizeScale);
									q.minY = y + (bc.offY * sizeScale);
									lineWidth += bc.stepX * sizeScale;
									x += bc.stepX * sizeScale;
									offset += bc.stepX * sizeScale;
									
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
					
					switch (alignment)
					{
						case Center, Right:
							for (i in 0...numQuads)
							{
								var q = quads[i];
								if (q.lineNumber == lineNumber + 1)
									q.minX -= offset;
							}
							x -= offset;
							for (i in 0...numQuads)
							{
								var q = quads[i];
								if (q.lineNumber == lineNumber)
									q.minX += offset;
							}
						default:
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
			
			if (code == ASCII.SPACE && alignment == Right)
			{
				wordNumber++;
				wordWidth = 0.;
			}
			wordWidth += stepX;
			
			var fq = quads[numQuads];
			if (fq == null)
			{
				fq = new FontQuad();
				fq.effect = new SpriteSheetEffect(sheet);
				quads[numQuads] = fq;
				
			}
			numQuads++;
			
			var a = fq.bound;
			a.minX = x + xOffset;
			a.minY = y + yOffset;
			a.maxX = a.minX + width;
			a.maxY = a.minY + height;
			fq.lineNumber = lineNumber;
			fq.wordNumber = wordNumber;
			fq.wordWidth = wordWidth;
			fq.bitmapChar = c;
			fq.sizeScale = sizeScale;
			fq.character = text.charCodeAt(i);
			
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
					
					for (i in 0...numQuads)
					{
						var q = quads[i];
						if (q.lineNumber == lineNumber)
							q.minX -= offset;
					}
					x -= offset;
				
				case Right:
					var offset = 0.;
					if (b.kerning) offset += kernAmount;
					
					for (i in 0...numQuads)
					{
						var q = quads[i];
						if (q.lineNumber == lineNumber)
						{
							offset = stepX;
							q.minX -= stepX;
						}
					}
					x -= offset;
				
				default:
			}
		}
		
		return numQuads;
	}
}

class CSpriteSheetEffect extends Effect
{
	var _e:SpriteSheetEffect;
	public var frame:Int;
	public function new(e:SpriteSheetEffect)
	{
		super();
		
		frame = 0;
		_e = e;
	}
	
	override public function draw(renderer:Renderer):Void
	{
		_e.frame = frame;
		renderer.drawSpriteSheetEffect(_e);
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
		this.text = text;
		this.bound = bound;
		this.align = align;
		this.size = size;
		this.kerning = kerning;
	}
}

private class FontQuad extends Quad
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
		super();
		bound = new AABB2();
	}
	
	override public function free():Void 
	{
		super.free();
		bitmapChar = null;
		bound = null;
	}
	
	public var minX(get_minX, set_minX):Float;
	inline function get_minX():Float
	{
		return bound.minX;
	}
	inline function set_minX(value:Float):Float
	{
		bound.setMinX(value);
		return value;
	}
	
	public var minY(get_minY, set_minY):Float;
	inline function get_minY():Float
	{
		return bound.minY;
	}
	inline function set_minY(value:Float):Float
	{
		bound.setMinY(value);
		return value;
	}
}