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
package de.polygonal.zz.render;

import de.polygonal.core.fmt.Sprintf;
import de.polygonal.core.math.Vec2;
import de.polygonal.motor.geom.primitive.AABB2;

using Reflect;

typedef SurfaceArgs =
{
	#if flash
	?hardware:Bool,
	?resizable:Bool
	#elseif nme
	?width:Int,
	?height:Int,
	?fps:Int,
	?color:Int,
	?hardware:Bool,
	?resizable:Bool
	#elseif js
	?resizable:Bool,
	canvasId:String
	#end
}

/**
 * <p>A RenderSurface provides a rendering surface for graphics applications.</p>
 */
class RenderSurface
{
	inline static var HARDWARE  = 0x01;
	inline static var RESIZABLE = 0x02;
	inline static var READY     = 0x04;
	
	/**
	 * The width of this surface in pixels.
	 */
	public static var width(default, null):Int = -1;
	
	/**
	 * The height of this surface in pixels.
	 */
	public static var height(default, null):Int = -1;
	
	/**
	 * The bounding box of this surface.
	 */
	public static var bound(default, null):AABB2 = null;
	
	public static var mouse(get_mouse, never):Vec2;
	static function get_mouse():Vec2
	{
		#if (flash || nme)
		_mouse.x = stage.mouseX;
		_mouse.y = stage.mouseY;
		#elseif js
		var rect = _canvas.getBoundingClientRect();
		_mouse.x = _tmp.x - rect.left;
		_mouse.y = _tmp.y - rect.top;
		#end
		return _mouse;
	}
	
	/**
	 * A callback function invoked whenever the size of this surface changes.
	 */
	public static var onResize:Int->Int->Void = null;
	
	static var _mouse:Vec2;
	static var _flags:Int = 0;
	static var _onCreate:Void->Void = null;
	
	#if (flash || nme)
	public static var stage(default, null):flash.display.Stage = null;
	public static var root(default, null):flash.display.Sprite = null;
	#if flash11
	public static var stage3D:flash.display.Stage3D = null;
	#end
	#end
	
	#if js
	public static var context(default, null):js.w3c.html5.Canvas2DContext.CanvasRenderingContext2D = null;
	static var _tmp:Vec2;
	static var _jq:js.JQuery = null;
	static var _canvas:js.w3c.html5.Core.HTMLCanvasElement = null;
	#end
	
	/**
	 * Returns true if this surface has been initialized.
	 */
	public static function isReady():Bool
	{
		return (_flags & READY) > 0;
	}
	
	/**
	 * Returns true if this surface supports hardware acceleration (e.g. Stage3D)
	 */
	public static function isHardware():Bool
	{
		return (_flags & HARDWARE) > 0;
	}
	
	/**
	 * Returns true if this surface is resizable.
	 */
	public static function isResizable():Bool
	{
		return (_flags & RESIZABLE) > 0;
	}
	
	public static function create(onCreate:Void->Void, onResize:Int->Int->Void = null, args:SurfaceArgs = null)
	{
		_onCreate = function()
		{
			trace(Sprintf.format('surface created (%03dx%03dpx)', [width, height]));
			_flags |= READY;
			onCreate();
		}
		
		RenderSurface.onResize = onResize;
		
		bound = new AABB2();
		bound.minX = 0;
		bound.minY = 0;
		
		_mouse = new Vec2();
		
		if (args.hasField('resizable') && args.resizable)
			_flags |= RESIZABLE;
		
		#if flash
		if (args != null)
		{
			if (args.hasField('hardware') && args.hardware)
				_flags |= HARDWARE;
		}
		initDisplayList();
		#elseif nme
		var fps = 60;
		var color = 0;
		width = 640;
		height = 800;
		_flags |= HARDWARE;
		
		if (args != null)
		{
			if (args.hasField('fps')) fps = args.fps;
			if (args.hasField('color')) color = args.color;
			if (args.hasField('width')) width = args.width;
			if (args.hasField('height')) height = args.height;
			
			if (args.hasField('hardware') && args.hardware)
				_flags |= HARDWARE;
			
			if (args.hasField('resizable') && args.resizable)
				_flags |= RESIZABLE;
		}
		
		try
		{
			nme.Lib.create(function() { initDisplayList(); }, width, height, fps, color,
				((isHardware() ? 1 : 0) * nme.Lib.HARDWARE) | (isResizable() ? 1 : 0) * nme.Lib.RESIZABLE);
		}
		catch (error:Dynamic)
		{
			//nme.Lib.create already called
			initDisplayList();
		}
		#elseif js
		_tmp = new Vec2();
		_jq = new js.JQuery(js.Lib.window).ready(
			function (_)
			{
				_canvas = cast js.Lib.document.getElementById(args.canvasId);
				
				context = _canvas.getContext('2d');
				if (isResizable())
				{
					trace('resizable!');
					_jq.resize(function(e:js.JQuery.JqEvent)
						{
							var w = js.Lib.window.innerWidth;
							var h = js.Lib.window.innerHeight;
							
							_canvas.style.setProperty('width', w + 'px');
							_canvas.style.setProperty('height', h + 'px');
							
							//_canvas.css('width', );
							//_canvas.css('height', h + 'py');
						});
					
					//untyped _canvas.webkitRequestFullScreen(); //Chrome
					//untyped _canvas.mozRequestFullScreen(); //Chrome
					//document.webkitCancelFullScreen(); //Chrome
					//document.mozCancelFullScreen(); //Firefox
				}
				
				bound.maxX = width = _canvas.width;
				bound.maxY = height = _canvas.height;
				
				_jq.mousemove(function(e:js.JQuery.JqEvent)
					{
						_tmp.x = e.pageX;
						_tmp.y = e.pageY;
					});
				
				_onCreate();
			});
		#end
	}
	
	public static function destroy():Void
	{
		#if flash11
		de.polygonal.zz.render.flash.util.DisplayListUtil.removeChildren(stage);
		if (isHardware())
		{
			try 
			{
				stage3D.removeEventListener(flash.events.Event.CONTEXT3D_CREATE, function(e) _onCreate());
			}
			catch(error:Dynamic) {}
		}
		#end
		
		_flags &= ~READY;
	}
	
	#if (flash || nme)
	static function initDisplayList()
	{
		stage = flash.Lib.current.stage;
		root = new flash.display.Sprite();
		root.name = 'root';
		root.addEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);
		flash.Lib.current.addChild(root);
	}
	
	static function onAddedToStage(e)
	{
		cast(e.target, flash.display.Sprite).removeEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);
		
		bound.maxX = width = stage.stageWidth;
		bound.maxY = height = stage.stageHeight;
		
		if (isResizable())
		{
			#if flash
			stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
			stage.align = flash.display.StageAlign.TOP_LEFT;
			stage.addEventListener(flash.events.Event.RESIZE, onStageResize);
			#end
		}
		
		if (isHardware())
		{
			#if flash11
			initStage3D();
			return;
			#end
		}
		
		_onCreate();
	}
	#end
	
	#if flash11
	static function initStage3D()
	{
		stage = flash.Lib.current.stage;
		stage3D = flash.Lib.current.stage.stage3Ds[0];
		stage3D.addEventListener(flash.events.Event.CONTEXT3D_CREATE, onContext3DCreate);
		stage3D.requestContext3D(cast flash.display3D.Context3DRenderMode.AUTO);
	}
	
	static function onContext3DCreate(_)
	{
		stage3D.removeEventListener(flash.events.Event.CONTEXT3D_CREATE, onContext3DCreate);
		_onCreate();
	}
	#end
	
	static function onStageResize(e)
	{
		#if flash
		bound.maxX = width = stage.stageWidth;
		bound.maxY = height = stage.stageHeight;
		#end
		
		trace('surface resized to %03dx%03d', width, height);
		if (onResize != null) onResize(width, height);
	}
}