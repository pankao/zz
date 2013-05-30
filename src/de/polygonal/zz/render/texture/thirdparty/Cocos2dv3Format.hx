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
package de.polygonal.zz.render.texture.thirdparty;

import de.polygonal.ds.TreeNode;
import de.polygonal.ds.XmlConvert;
import de.polygonal.zz.render.texture.Rect;
import de.polygonal.zz.render.texture.Size;
import de.polygonal.zz.render.texture.SpriteAtlasFormat;

class Cocos2dv3Format extends SpriteAtlasFormat
{
	public function new(src:String)
	{
		super();
		
		var tree = XmlConvert.toTreeNode(src);
		
		try 
		{
			var metadata = getKey(tree, 'metadata');
			var format:Int = getKeyValue(metadata, 'format');
			if (format != 3) throw 'only v3 is supported';
			
			var size:Size = getKeyValue(metadata, 'size');
			sheetW = Std.int(size.x);
			sheetH = Std.int(size.y);
			
			var frames = getKey(tree, 'frames');
			
			var c = frames.next.children;
			while (c != null)
			{
				if (c.val.name == 'key')
				{
					var name = c.val.value;
					var dict = c.next;
					var sourceColorRect:Rect  = getKeyValue(c, 'sourceColorRect');
					var spriteOffset:Size     = getKeyValue(c, 'spriteOffset');
					var spriteSize:Size       = getKeyValue(c, 'spriteSize');
					var spriteSourceSize:Size = getKeyValue(c, 'spriteSourceSize');
					var trimmed:Bool          = getKeyValue(c, 'spriteTrimmed');
					var textureRect:Rect      = getKeyValue(c, 'textureRect');
					var textureRotated:Bool   = getKeyValue(c, 'textureRotated');
					
					this.frames.push(textureRect);
					this.names.push(name);
				}
				
				c = c.next;
			}
		}
		catch (error:Dynamic)
		{
			trace('invalid xml file: ' + error);
		}
	}
	
	function getKey(sub:TreeNode<XmlNodeData>, key:String):TreeNode<XmlNodeData>
	{
		for (i in sub)
			if (i.name == 'key' && i.value == key)
				return i.treeNode;
		return null;
	}
	
	function getKeyValue(sub:TreeNode<XmlNodeData>, key:String):Dynamic
	{
		var keyNode = getKey(sub.next, key);
		return parseValue(keyNode);
	}
	
	function parseValue(key:TreeNode<XmlNodeData>):Dynamic
	{
		var data = key.next.val;
		switch (data.name)
		{
			case 'integer':
				return Std.parseInt(data.value);
			
			case 'false':
				return false;
			
			case 'true':
				return true;
			
			case 'string':
				var s = data.value;

				var ereg = ~/{(-?\d+),(-?\d+)},{(-?\d+),(-?\d+)}/;
				if (ereg.match(s))
				{
					var x0 = Std.parseInt(ereg.matched(1));
					var y0 = Std.parseInt(ereg.matched(2));
					var x1 = Std.parseInt(ereg.matched(3));
					var y1 = Std.parseInt(ereg.matched(4));
					return new Rect(x0, y0, x1, y1);
				}
				ereg = ~/{(-?\d+),(-?\d+)}/;
				if (ereg.match(s))
				{
					var x = Std.parseInt(ereg.matched(1));
					var y = Std.parseInt(ereg.matched(2));
					return new Size(x, y);
				}

				return s;
		}
		
		return throw 'unknown type';
	}
}