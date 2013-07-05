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
package de.polygonal.zz.render.module.flash.stage3d;

import de.polygonal.core.fmt.NumberFormat;
import de.polygonal.core.fmt.Sprintf;
import de.polygonal.core.util.Assert;
import de.polygonal.ds.Bits;
import de.polygonal.ds.DA;
import de.polygonal.ds.IntHashTable;
import de.polygonal.zz.render.effect.Effect.*;
import de.polygonal.zz.render.effect.*;
import de.polygonal.zz.render.module.flash.stage3d.paintbox.*;
import de.polygonal.zz.render.module.flash.stage3d.*;
import de.polygonal.zz.render.module.RenderModuleConfig;
import de.polygonal.zz.render.RenderSurface;
import de.polygonal.zz.render.texture.Image;
import de.polygonal.zz.render.texture.Tex;
import de.polygonal.zz.scene.*;
import flash.display3D.*;
import haxe.ds.IntMap;

using Reflect;

class Stage3dRenderer extends Renderer
{
	public var context(default, null):Context3D;
	public var numCallsToDrawTriangle:Int;
	
	//private
	public var prevStage3dTexture:Stage3dTexture;
	public var currStage3dTexture:Stage3dTexture;
	public var currBrush:Stage3dBrush;
	
	/**
	 * 0=use vertex buffer, 1=use constant registers
	 */
	public var batchStrategy(default, null):Int;
	
	var _antiAliasMode:Int = -1;
	var _batchActive:Bool;
	var _currBrush:Stage3dBrush;
	var _paintBox:IntHashTable<Stage3dBrush>;
	var _textureHandles:IntHashTable<Stage3dTexture>;
	var _srcBlendFactorLUT:Array<Context3DBlendFactor>;
	var _dstBlendFactorLUT:Array<Context3DBlendFactor>;
	var _alphaState:AlphaState;
	var _textureFlags:Int;
	var _numDeviceLost:Int;
	var _enableErrorChecking:Bool;
	
	public function new(config:RenderModuleConfig)
	{
		if (!RenderSurface.isHardware()) throw 'stage3d not available';
		
		if (config != null)
		{
			if (config.hasField('enableErrorChecking') && config.enableErrorChecking) _enableErrorChecking = true;
			if (config.hasField('preferConstantOverVertexBatching')) batchStrategy = 1;
			if (config.hasField('textureFlags')) _textureFlags = config.textureFlags;
			if (config.hasField('antiAliasMode')) _antiAliasMode = 1 << Type.enumIndex(config.antiAliasMode);
		}
		
		if (_textureFlags == 0) _textureFlags = Stage3dTextureFlag.PRESET_QUALITY_MEDIUM;
		
		initContext();
		
		super(config); //requires context; calls onViewPortChange()
		
		if (config != null)
		{
			if (config.hasField('maxBatchSize'))
				maxBatchSize = config.maxBatchSize;
		}
		
		_numDeviceLost = RenderSurface.numDeviceLost;
		
		if (_antiAliasMode == -1) _antiAliasMode = 1 << Type.enumIndex(Stage3dAntiAliasMode.Low);
		
		initPaintBox();
		
		_srcBlendFactorLUT =
		[
			Context3DBlendFactor.ZERO,
			Context3DBlendFactor.ONE,
			Context3DBlendFactor.DESTINATION_COLOR,
			Context3DBlendFactor.ONE_MINUS_DESTINATION_COLOR,
			Context3DBlendFactor.SOURCE_ALPHA,
			Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA,
			Context3DBlendFactor.DESTINATION_ALPHA,
			Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA
		];
		
		_dstBlendFactorLUT =
		[
			Context3DBlendFactor.ZERO,
			Context3DBlendFactor.ONE,
			Context3DBlendFactor.SOURCE_COLOR,
			Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR,
			Context3DBlendFactor.SOURCE_ALPHA,
			Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA,
			Context3DBlendFactor.DESTINATION_ALPHA,
			Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA
		];
		
		_textureHandles = new IntHashTable(32, 32, false, 32);
		
		drawDeferred = drawDeferredBatch;
	}
	
	override public function free():Void
	{
		for (handle in _textureHandles)
		{
			if (handle == null) continue;
			handle.free();
		}
		_textureHandles.free();
		_textureHandles = null;
		
		context.dispose();
		context = null;
		
		super.free();
	}
	
	override public function freeTex(image:Image):Void
	{
		var tex = _textureLookup.get(image.key);
		freeStage3dTexture(tex);
		super.freeTex(image);
	}
	
	override public function createTex(image:Image):Tex
	{
		return new Tex(image, true, true);
	}
	
	override public function onViewPortChange():Void
	{
		super.onViewPortChange();
		configureBackBuffer();
	}
	
	/**
	 * Default is <em>Stage3dAntiAliasMode.Low</em>.
	 */
	public function setAntiAlias(mode:Stage3dAntiAliasMode):Void
	{
		var flag =
		switch (mode)
		{
			case None:   0;
			case Low:    2;
			case High:   4;
			case Ultra: 16;
		}
		
		if (flag != _antiAliasMode)
		{
			_antiAliasMode = flag;
			if (context != null) configureBackBuffer();
		}
	}
	
	public function initStage3dTexture(tex:Tex):Stage3dTexture
	{
		var t = _textureHandles.get(tex.key);
		if (t == null)
		{
			L.d(Sprintf.format('upload texture #%d from image #%d', [tex.key, tex.image.key]), 's3d');
			t = new Stage3dTexture(tex);
			t.flags |= _textureFlags;
			
			t.upload(context);
			_textureHandles.set(tex.key, t);
		}
		return t;
	}
	
	/**
	 * Frees all gpu resources associated with the given <code>tex</code> object.
	 */
	public function freeStage3dTexture(tex:Tex):Void
	{
		var t = _textureHandles.get(tex.key);
		if (t != null)
		{
			L.d(Sprintf.format('free stage3d texture #%d (image #%d)', [tex.key, tex.image.key]), 's3d');
			t.free();
			_textureHandles.clr(tex.key);
		}
	}
	
	override public function drawEffect(effect:Effect):Void
	{
		currStage3dTexture = null;
		var brush = findBrush(effect.flags, 0, false);
		brush.add(currGeometry);
		brush.draw(this);
	}
	
	override public function drawTextureEffect(effect:TextureEffect):Void
	{
		super.drawTextureEffect(effect);
		
		currTexture = effect.tex;
		currStage3dTexture = initStage3dTexture(currTexture);
		
		var brush = findBrush(effect.flags, currStage3dTexture.flags, false);
		brush.add(currGeometry);
		brush.draw(this);
	}
	
	override public function drawSpriteSheetEffect(effect:SpriteSheetEffect):Void
	{
		if (_batchActive)
		{
			L.d('draw sprite sheet effect batched', 's3d');
		}
		else
		{
			super.drawSpriteSheetEffect(effect);
			
			//single drawTriangles() call per object
			currTexture = effect.tex;
			currStage3dTexture = initStage3dTexture(currTexture);
			
			var brush = findBrush(effect.flags, currStage3dTexture.flags, false);
			brush.add(currGeometry);
			brush.draw(this);
		}
	}
	
	/*override public function drawBitmapFont(effect:BitmapFontEffect)
	{
		//should be a mesh...
		var mesh:TriMesh = cast currGeometry;
		throw 'todo';
	}*/
	
	override public function drawDeferredBatch():Void
	{
		//nothing to draw?
		if (_deferredObjectsList.__next == null) return;
		
		_batchActive = true;
		
		//temporarily disable deferred drawing
		var save = drawDeferred;
		drawDeferred = null;
		
		var numBatchCalls = 0;
		var currEffectFlags = -1;
		var currStateFlags = -1;
		var states:DA<GlobalState> = null;
		var prevBrush:Stage3dBrush = null;
		var currBrush:Stage3dBrush = null;
		
		currTexture = null;
		
		var o = _deferredObjectsList.__next;
		while (o != null)
		{
			if (o.isNode())
			{
				//when deferred drawing is active, a call to drawNode() simply adds the node to the list of deferred objects;
				//since deferred drawing is temporarly disabled, drawNode(o) will draw the effect attached to the node.
				_deferredObjectsNode = o;
				drawNode(o.__node);
				o = o.__next;
				continue;
			}
			
			var g = o.__geometry;
			
			//nothing to draw; skip
			if (o.effect == null)
			{
				o = o.__next;
				continue;
			}
			
			var effect = o.effect;
			var effectFlags = effect.flags;
			if (currEffectFlags < 0)
			{
				//insert first first geometry node into batch
				currEffectFlags = effectFlags;
				currTexture = effect.tex;
				currStateFlags = g.stateFlags;
				states = g.states;
				
				if (allowGlobalState)
					setGlobalState(states);
				
				currStage3dTexture =
				if (currTexture != null)
					initStage3dTexture(currTexture);
				else
					null;
				
				prevBrush = null;
				currBrush = findBrush(effectFlags, currStage3dTexture != null ? currStage3dTexture.flags : 0, true);
				currBrush.add(g);
				
				o = o.__next;
				continue;
			}
			
			//render state changed?
			var effectsChanged = effectFlags != currEffectFlags;
			var textureChanged = effect.tex != currTexture;
			var stateChanged   = g.stateFlags != currStateFlags;
			var batchExhausted = currBrush.isFull();
			
			if (effectsChanged || textureChanged || stateChanged || batchExhausted)
			{
				//current batch needs to be drawn
				currBrush.draw(this);
				numBatchCalls++;
				
				//initialize new batch for current geometry
				currEffectFlags = effectFlags;
				currTexture = effect.tex;
				currStateFlags = g.stateFlags;
				states = g.states;
				
				if (stateChanged && allowGlobalState)
					setGlobalState(states);
				
				currStage3dTexture =
				if (currTexture != null)
					initStage3dTexture(currTexture);
				else
					null;
				
				prevBrush = currBrush;
				if (effectsChanged || textureChanged)
					currBrush = findBrush(effectFlags, currStage3dTexture != null ? currStage3dTexture.flags : 0, true);
			}
			
			currBrush.add(g);
			
			o = o.__next;
		}
		
		//draw remainder
		if (currBrush != null && !currBrush.isEmpty())
		{
			if (allowGlobalState)
				setGlobalState(states);
			
			currBrush.draw(this);
			numBatchCalls++;
		}
		
		currStage3dTexture = null;
		currTexture = null;
		
		//restore deferred drawing
		drawDeferred = save;
		
		_batchActive = false;
	}
	
	override public function setAlphaState(state:AlphaState):Void
	{
		_alphaState = state;
		context.setBlendFactors
		(
			_srcBlendFactorLUT[Type.enumIndex(state.src)],
			_dstBlendFactorLUT[Type.enumIndex(state.dst)]
		);
	}
	
	override function drawElements():Void
	{
		if (currGeometry.type == GeometryType.QUAD)
		{
			if (currEffect == null)
				return;
			
			var e = currEffect.flags;
			
			var textureFlags = 0;
			
			if (allowTextures)
			{
				if (currTexture != null)
				{
					currStage3dTexture = initStage3dTexture(currTexture);
					textureFlags = currStage3dTexture.flags;
				}
			}
			else
				e &= ~(EFFECT_TEXTURE | EFFECT_TEXTURE_PMA);
			
			var brush = findBrush(e, textureFlags, false);
			brush.add(currGeometry);
			brush.draw(this);
		}
		else
		if (currGeometry.type == GeometryType.TRIMESH)
		{
			
		}
	}
	
	override function onBeginScene():Void
	{
		if (RenderSurface.numDeviceLost != _numDeviceLost)
		{
			L.w('device lost', 's3d');
			_numDeviceLost = RenderSurface.numDeviceLost;
			handleDeviceLost();
		}
		
		context.clear(_backgroundColor.r, _backgroundColor.g, _backgroundColor.b, _backgroundColor.a);
		numCallsToDrawTriangle = 0;
	}
	
	override function onEndScene():Void
	{
		context.present();
	}
	
	function handleDeviceLost():Void
	{
		initContext();
		configureBackBuffer();
		setAlphaState(_alphaState);
		
		//upload textures to new context
		for (tex in _textureLookup)
		{
			if (_textureHandles.hasKey(tex.key))
				_textureHandles.get(tex.key).free();
		}
		_textureHandles.clear(true);
		for (tex in _textureLookup)
			initStage3dTexture(tex);
		
		//init index & vertex buffers, shaders and programs
		initPaintBox();
	}
	
	function initContext():Void
	{
		context = RenderSurface.stage3d.context3D;
		context.setCulling(Context3DTriangleFace.NONE);
		context.setDepthTest(false, Context3DCompareMode.ALWAYS);
		
		context.enableErrorChecking = _enableErrorChecking;
		
		#if debug
		context.enableErrorChecking = true;
		#end
		
		if (_enableErrorChecking) L.w('error checking is enabled');
		L.i('driverInfo: ${context.driverInfo}', 's3d');
	}
	
	function initPaintBox():Void
	{
		if (_paintBox != null)
		{
			//some brushes are shared
			for (brush in _paintBox.toValSet()) brush.free();
			_paintBox.clear(true);
		}
		
		_paintBox = new IntHashTable(256, 256, false, 256);
		
		registerBrush(Stage3dBrushRectNull, 0, 0);
		
		registerSharedBrush(Stage3dBrushRectSolidColor     , EFFECT_COLOR | EFFECT_ALPHA | EFFECT_COLOR_XFORM, 0, false);
		registerSharedBrush(Stage3dBrushRectSolidColorBatch, EFFECT_COLOR | EFFECT_ALPHA | EFFECT_COLOR_XFORM, 0, true);
		
		L.i('using texture flags: ' + Stage3dTextureFlag.print(_textureFlags));
		
		registerBrush(Stage3dBrushRectTexture, EFFECT_TEXTURE                                        , _textureFlags, false);
		registerBrush(Stage3dBrushRectTexture, EFFECT_TEXTURE | EFFECT_ALPHA                         , _textureFlags, false);
		registerBrush(Stage3dBrushRectTexture, EFFECT_TEXTURE | EFFECT_COLOR_XFORM                   , _textureFlags, false);
		registerBrush(Stage3dBrushRectTexture, EFFECT_TEXTURE | EFFECT_ALPHA | EFFECT_COLOR_XFORM    , _textureFlags, false);
		registerBrush(Stage3dBrushRectTexture, EFFECT_TEXTURE_PMA                                    , _textureFlags, false);
		registerBrush(Stage3dBrushRectTexture, EFFECT_TEXTURE_PMA | EFFECT_ALPHA                     , _textureFlags, false);
		registerBrush(Stage3dBrushRectTexture, EFFECT_TEXTURE_PMA | EFFECT_COLOR_XFORM               , _textureFlags, false);
		registerBrush(Stage3dBrushRectTexture, EFFECT_TEXTURE_PMA | EFFECT_ALPHA | EFFECT_COLOR_XFORM, _textureFlags, false);
		
		registerBrush(Stage3dBrushRectTextureBatch, EFFECT_TEXTURE                                        , _textureFlags, true);
		registerBrush(Stage3dBrushRectTextureBatch, EFFECT_TEXTURE | EFFECT_ALPHA                         , _textureFlags, true);
		registerBrush(Stage3dBrushRectTextureBatch, EFFECT_TEXTURE | EFFECT_COLOR_XFORM                   , _textureFlags, true);
		registerBrush(Stage3dBrushRectTextureBatch, EFFECT_TEXTURE | EFFECT_ALPHA | EFFECT_COLOR_XFORM    , _textureFlags, true);
		registerBrush(Stage3dBrushRectTextureBatch, EFFECT_TEXTURE_PMA                                    , _textureFlags, true);
		registerBrush(Stage3dBrushRectTextureBatch, EFFECT_TEXTURE_PMA | EFFECT_ALPHA                     , _textureFlags, true);
		registerBrush(Stage3dBrushRectTextureBatch, EFFECT_TEXTURE_PMA | EFFECT_COLOR_XFORM               , _textureFlags, true);
		registerBrush(Stage3dBrushRectTextureBatch, EFFECT_TEXTURE_PMA | EFFECT_ALPHA | EFFECT_COLOR_XFORM, _textureFlags, true);
	}
	
	function configureBackBuffer():Void
	{
		try
		{
			context.configureBackBuffer(width, height, _antiAliasMode, false);
		}
		catch (unknown:Dynamic)
		{
			L.e('configureBackBuffer failed: $unknown');
		}
	}
	
	function registerBrush(brush:Class<Stage3dBrush>, supportedEffects:Int, textureFlags = 0, supportsBatching = false):Void
	{
		var args:Array<Dynamic> = [this, context, supportedEffects, textureFlags];
		if (supportedEffects & (EFFECT_TEXTURE | EFFECT_TEXTURE_PMA) == 0) args.pop(); //no texture
		var brush = Type.createInstance(brush, args);
		var key = getBrushKey(supportedEffects, textureFlags, supportsBatching);
		_paintBox.set(key, brush);
	}
	
	function registerSharedBrush(brush:Class<Stage3dBrush>, supportedEffects:Int, textureFlags:Int, supportsBatching = false):Void
	{
		var map = new IntMap<Int>();
		var k = 32 - Bits.nlz(supportedEffects);
		for (i in 0...k)
		{
			var mask = 1 << i;
			for (j in 0...k)
			{
				if (i == j) continue;
				map.set(mask, mask);
				mask |= (1 << j);
				
			}
		}
		
		var args:Array<Dynamic> = [this, context, supportedEffects, textureFlags];
		if (supportedEffects & (EFFECT_TEXTURE | EFFECT_TEXTURE_PMA) == 0) args.pop();
		var brush = Type.createInstance(brush, args);
		
		var exclude = 0;
		var i = 0;
		var t = supportedEffects;
		while (t != 0)
		{
			if (t & 1 == 0)
				exclude |= 1 << i;
			i++;
			t >>= 1;
		}
		
		for (mask in map.keys())
			if (mask & exclude == 0)
				_paintBox.set(getBrushKey(mask, textureFlags, supportsBatching), brush);
	}
	
	function findBrush(supportedEffects:Int, textureFlags:Int, preferBatching:Bool):Stage3dBrush
	{
		var key = getBrushKey(supportedEffects, textureFlags, preferBatching);
		
		if (_paintBox.hasKey(key))
			return _paintBox.get(key);
		else
		{
			var brushClass = Type.getClass(_paintBox.get(getBrushKey(supportedEffects, _textureFlags, preferBatching)));
			registerBrush(brushClass, supportedEffects, textureFlags, preferBatching);
			
			var brush = _paintBox.get(key);
			
			#if debug
			D.assert(brush != null, Sprintf.format('no registered found for effect %b and texture flags %b', [supportedEffects, textureFlags]));
			#end
			
			return brush;
		}
	}
	
	inline function getBrushKey(supportedEffects:Int, textureFlags:Int, supportsBatching:Bool):Int
	{
		//smoothing flag has no effect
		return (supportedEffects & ~EFFECT_SMOOTH) | textureFlags | (supportsBatching ? (1 << 25) : 0);
	}
}