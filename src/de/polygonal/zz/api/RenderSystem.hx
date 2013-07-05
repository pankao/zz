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
package de.polygonal.zz.api;

import de.polygonal.core.util.Assert;
import de.polygonal.ds.IntIntHashTable;
import de.polygonal.gl.color.ColorRGBA;
import de.polygonal.gl.color.RGBA;
import de.polygonal.zz.render.effect.Effect;
import de.polygonal.zz.render.effect.SpriteSheetEffect;
import de.polygonal.zz.render.effect.TextEffect;
import de.polygonal.zz.render.effect.TextureEffect;
import de.polygonal.zz.render.module.RenderModule;
import de.polygonal.zz.render.module.RenderModuleConfig;
import de.polygonal.zz.render.RenderSurface;
import de.polygonal.zz.render.texture.Image;
import de.polygonal.zz.render.texture.ImageData;
import de.polygonal.zz.render.texture.Rect;
import de.polygonal.zz.render.texture.SpriteAtlas;
import de.polygonal.zz.render.texture.SpriteAtlasFormat;
import de.polygonal.zz.render.texture.SpriteSheet;
import de.polygonal.zz.render.texture.SpriteStrip;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.render.texture.thirdparty.BMFontFormat;
import de.polygonal.zz.scene.Node;
import de.polygonal.zz.scene.Renderer;
import de.polygonal.zz.scene.Spatial;
import haxe.ds.StringMap;

#if flash
#if flash11
import de.polygonal.zz.render.module.flash.stage3d.Stage3dRenderer;
#end
import de.polygonal.zz.render.module.flash.cpu.BitmapDataRenderer;
import de.polygonal.zz.render.module.flash.cpu.DisplayListRenderer;
//import de.polygonal.zz.render.module.flash.cpu.GraphicsRenderer;
#else

#elseif js
import de.polygonal.zz.render.module.js.CanvasRenderer;
#elseif cpp
import de.polygonal.zz.render.module.nme.TileRenderer;
#end
 
class RenderSystem
{
	public static var sceneGraph(default, null):Node;
	public static var renderer:Renderer;
	
	public static var images:StringMap<Image>;
	#if flash11_4
	public static var compressedImages:StringMap<flash.utils.ByteArray>;
	#end
	
	static var _sheetMap:StringMap<SpriteSheet>;
	static var _bmFontMap:StringMap<BMFontFormat>;
	
	static var _textureUsageCount:IntIntHashTable = null;
	
	public static function init(type:RenderModule = null, config:RenderModuleConfig = null):Void
	{
		if (type == null)
		{
			//infer render-module from platform
			#if flash
				#if flash11
				if (RenderSurface.isHardware())
					renderer = new Stage3dRenderer(config);
				else
					renderer = new BitmapDataRenderer(config);
				#else
					renderer = new BitmapDataRenderer(config);
				#end
			#elseif cpp
				renderer = new TileRenderer(config);
			#elseif js
				renderer = new CanvasRenderer(config);
			#end
		}
		else
		{
			switch (type)
			{
				case FlashStage3d:
					#if flash11
					renderer = new Stage3dRenderer(config);
					#end
				
				case FlashDisplayList:
					renderer = new DisplayListRenderer(config);
				
				case FlashBitmapData:
					renderer = new BitmapDataRenderer(config);
				
				case FlashGraphics:
					//renderer = new GraphicsRenderer();
				
				case NmeTile:
					#if cpp
					new TileRenderer(config);
					#end
				
				case Html5Canvas:
					#if js
					new CanvasRenderer(config);
					#end
			}
			
			D.assert(renderer != null, 'renderer != null');
		}
		
		sceneGraph = new Node('sceneGraphRoot');
		images = new StringMap();
		compressedImages = new StringMap();
		
		_textureUsageCount = new IntIntHashTable(4096);
		
		renderer.setBackgroundColor(0, 0, 0, 1);
		
		sceneGraph.enableUpdateBV(false);
	}
	
	//adds x to the scene graph root node
	public static function addChild(x:Tile):Void
	{
		sceneGraph.addChild(x.sgn);
	}
	
	public static function setBackgroundColor(color:ColorRGBA):Void
	{
		renderer.setBackgroundColor(color.r, color.g, color.b, color.a);
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
			L.w('image with id $imageId already registered');
			return;
		}
		
		var image = new Image(data, data.width, data.height, true);
		image.id = imageId;
		images.set(imageId, image);
		var key = image.key;
		L.d('register image "$imageId" -> #$key');
	}
	
	#if flash11_4
	static public function registerCompressedImage(imageId:String, data:flash.utils.ByteArray):Void
	{
		if (images.exists(imageId))
		{
			L.w('image with id $imageId already registered');
			return;
		}
		
		var image = Image.ofBytes(data);
		image.id = imageId;
		images.set(imageId, image);
		var key = image.key;
		L.d('register ATF "$imageId" -> #$key');
	}
	#end
	
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
				L.w('sprite atlas with id $imageId already registered');
				return;
			}
		}
		
		var tex = initTexture(imageId);
		var atlas = new SpriteAtlas(tex, format);
		if (_sheetMap == null) _sheetMap = new StringMap();
		_sheetMap.set(imageId, atlas);
		
		L.d('register sprite atlas with imageId "$imageId"');
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
		D.assert(sheet != null, 'no sprite sheet found ($sheetId)');
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
		if (Std.is(renderer, Stage3dRenderer))
			cast(renderer, Stage3dRenderer).initStage3dTexture(tex);
		#end
	}
}