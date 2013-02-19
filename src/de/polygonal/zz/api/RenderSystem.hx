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
package de.polygonal.zz.api;

import de.polygonal.ds.IntIntHashTable;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.effect.SpriteSheetEffect;
import de.polygonal.zz.render.effect.TextEffect;
import de.polygonal.zz.render.effect.TextureEffect;
import de.polygonal.zz.render.texture.Image;
import de.polygonal.zz.render.texture.ImageData;
import de.polygonal.zz.render.texture.SpriteAtlas;
import de.polygonal.zz.render.texture.SpriteAtlasFormat;
import de.polygonal.zz.render.texture.SpriteSheet;
import de.polygonal.zz.render.texture.SpriteStrip;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.render.texture.thirdparty.BMFontFormat;
import de.polygonal.zz.scene.Node;
import de.polygonal.zz.scene.Renderer;
import haxe.ds.StringMap;

#if flash11
import de.polygonal.zz.render.module.flash.stage3d.Stage3DRenderer;
#end
 
class RenderSystem
{
	public static var sceneGraph:Node;
	
	public static var renderer:Renderer;
	
	public static var images:StringMap<Image>;
	
	static var _sheetMap:StringMap<SpriteSheet>;
	static var _bmFontMap:StringMap<BMFontFormat>;
	
	static var _textureUsageCount:IntIntHashTable = null;
	
	public static function init():Void
	{
		sceneGraph = new Node('sceneGraphRoot');
		images = new StringMap();
		
		_textureUsageCount = new IntIntHashTable(4096);
		
		#if flash11
		renderer = new de.polygonal.zz.render.module.flash.stage3d.Stage3DRenderer();
		//renderer = new de.polygonal.zz.render.module.flash.misc.BitmapDataRenderer();
		//RenderSurface.root.addChild(cast(renderer, BitmapDataRenderer).getBitmap());
		
		#elseif flash10
		null;
		#elseif nme
		renderer = new de.polygonal.zz.render.module.nme.TileRenderer();
		#elseif js
		renderer = new de.polygonal.zz.render.module.js.CanvasRenderer();
		#end
		
		renderer.setBackgroundColor(0, 0, 0, 1);
		
		sceneGraph.enableUpdateBV(false);
	}
	
	public static function drawScene():Void
	{
		renderer.drawScene(sceneGraph);
	}
	
	static public function getSheet(id:String):SpriteSheet
	{
		#if debug
		if (!_sheetMap.exists(id))
			D.assert(!_sheetMap.exists(id), 'sprite sheet does not exist');
		#end
		return _sheetMap.get(id);
	}
	
	static public function createTile(id:String):Tile
	{
		return new Tile(id);
	}
	
	static public function getImage(imageId:String):Image
	{
		if (!images.exists(imageId))
			throw 'image with id "' + imageId + '" does not exits';
		return images.get(imageId);
	}
	
	static public function registerImage(imageId:String, data:ImageData):Void
	{
		if (images.exists(imageId))
		{
			trace('image with id %s already registered', imageId);
			return;
		}
		
		var image = Image.ofData(data);
		image.id = imageId;
		images.set(imageId, image);
		trace('register image %s -> #%d', imageId, image.key);
	}
	
	static public function initTexture(imageId:String):Tex
	{
		return renderer.initTex(getImage(imageId));
	}
	
	static public function freeTexture(tex:Tex):Void
	{
		var count = _textureUsageCount.get(tex.key);
		if (count == 1)
		{
			_textureUsageCount.clr(tex.key);
			renderer.freeTex(tex.image);
		}
	}
	
	static public function registerSpriteAtlas(imageId:String, format:SpriteAtlasFormat):Void
	{
		if (_sheetMap != null)
		{
			if (_sheetMap.exists(imageId))
			{
				trace('sprite atlas with id %s already registered', imageId);
				return;
			}
		}
		
		var tex = initTexture(imageId);
		var atlas = new SpriteAtlas(tex, format);
		if (_sheetMap == null) _sheetMap = new StringMap();
		_sheetMap.set(imageId, atlas);
	}
	
	static public function registerSpriteStrip(imageId:String, rows:Int, cols:Int):Void
	{
		var tex = initTexture(imageId);
		var strip = new SpriteStrip(tex, rows, cols);
		if (_sheetMap == null) _sheetMap = new StringMap();
		_sheetMap.set(imageId, strip);
	}
	
	static public function registerTextEffect(imageId:String, def:String):Void
	{
		initTexture(imageId);
		if (_bmFontMap == null) _bmFontMap = new StringMap();
		_bmFontMap.set(imageId, new BMFontFormat(def));
	}
	
	static public function createColorEffect(color:Int):Effect
	{
		var effect = new Effect();
		effect.color = color;
		return effect;
	}
	
	static public function createTextureEffect(imageId:String):TextureEffect
	{
		var tex = initTexture(imageId);
		
		var count = _textureUsageCount.get(tex.key);
		if (count == IntIntHashTable.KEY_ABSENT)
			_textureUsageCount.set(tex.key, 1);
		else
			_textureUsageCount.set(tex.key, count + 1);
		
		uploadTexture(tex);
		return new TextureEffect(tex);
	}
	
	static public function createSpriteSheetEffect(sheetId:String):SpriteSheetEffect
	{
		var sheet = _sheetMap.get(sheetId);
		
		#if debug
		D.assert(sheet != null, 'no sprite sheet defined');
		#end
		
		uploadTexture(sheet.tex);
		return new SpriteSheetEffect(sheet);
	}
	
	static public function createTextEffect(id:String):TextEffect
	{
		var image = getImage(id);
		var tex = renderer.initTex(image);
		uploadTexture(tex);
		return new TextEffect(_bmFontMap.get(id), tex);
	}
	
	inline static function uploadTexture(tex:Tex):Void
	{
		#if flash11
		if (Std.is(renderer, Stage3DRenderer))
			cast(renderer, Stage3DRenderer).initStage3DTexture(tex);
		#end
	}
}