package de.polygonal.zz.render.texture.thirdparty;

import de.polygonal.zz.render.texture.Rect;
import de.polygonal.zz.render.texture.SpriteAtlasFormat;
import haxe.xml.Fast;

class StarlingFormat extends SpriteAtlasFormat
{
	public var imagePath:String;
	
	public function new(src:String, imageW:Int, imageH:Int)
	{
		super();
		
		sheetW = imageW;
		sheetH = imageH;
		
		try
		{
			var xml = Xml.parse(src).firstElement();
			var f = new Fast(xml);
			
			imagePath = f.att.imagePath;
			
			for (e in f.nodes.SubTexture)
			{
				var x = Std.parseInt(e.att.x);
				var y = Std.parseInt(e.att.y);
				var w = Std.parseInt(e.att.width);
				var h = Std.parseInt(e.att.height);
				frames.push(new Rect(x, y, w, h));
				names.push(e.att.name);
			}
		}
		catch (error:Dynamic)
		{
			trace('invalid xml file: ' + error);
		}
	}
}