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
package de.polygonal.zz.render;

import de.polygonal.core.math.Vec2;
import de.polygonal.motor.geom.primitive.AABB2;
import de.polygonal.core.math.Mathematics;

using Reflect;

typedef SurfaceArgs =
{
	#if flash
	?hardware:Bool,
	?resizable:Bool
	#if flash11_4
	,?profile:flash.display3D.Context3DProfile
	#end
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
	inline static var READY     = 0x02;
	
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
	
	/**
	 * The mouse position relative to the top-left corner of the surface.
	 */
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
	
	public static function computeBoundShowAll(contentW:Int, contentH:Int, cropThreshold = 0., allowNonUniformScale = false):{x:Float, y:Float, scaleX:Float, scaleY:Float}
	{
		var sW = RenderSurface.width;
		var sH = RenderSurface.height;
		var sX = sW / contentW;
		var sY = sH / contentH;
		var x = 0.;
		var y = 0.;
		
		if (sX <= sY)
		{
			//landscape
			y = Math.round((sH - (contentH * sX)) / 2);
			
			var letterbox = sH - (sX * contentH);
			L.d('letterbox: ' + Math.ceil(letterbox));
			
			//allow some cropping (left/right) if letterbox covers less than 2 percent of the screen height
			if (letterbox / sH < cropThreshold)
			{
				sX = sY;
				sY = sX;
				y = 0;
				x = Math.round((sW - (contentW * sX)) / 2);
			}
			else
			{
				sY = sX;
				if (allowNonUniformScale)
				{
					//in case letterbox is used, allow some distortion so new height snaps to a full pixel
					var t = Math.round(contentH * sX);
					if (!M.isEven(t)) t--;
					
					sY = t / contentH;
					y = (sH - t) >> 1;
				}
			}
		}
		else
		{
			//portrait
			x = Math.round((sW - (contentW * sY)) / 2);
			
			var pillarbox = sW - (sY * contentW);
			
			L.d('pillarbox: ' + Math.ceil(pillarbox));
			
			//allow some cropping (top/bottom) if pillarbox covers less than 2 percent of the screen width
			if (pillarbox / sW < cropThreshold)
			{
				sY = sX;
				sX = sY;
				x = 0;
				y = Math.round((sH - (contentH * sY)) / 2);
			}
			else
			{
				sX = sY;
				if (allowNonUniformScale)
				{
					//in case pillarbox is used, allow some distortion so new width snaps to a full pixel
					var t = Math.round(contentW * sY);
					if (!M.isEven(t)) t--;
					
					sX = t / contentW;
					x = (sW - t) >> 1;
				}
			}
		}
		
		L.d('content scale: x=${sX} y=${sY}');
		L.d('content size: ${contentW*sX}/${contentH*sY} px');
		L.d('content offset: ${x}/${y} px');
		
		return {x: x, y: y, scaleX: sX, scaleY: sY};
	}
	
	static var _mouse:Vec2;
	static var _flags:Int = 0;
	static var _onCreate:Void->Void = null;
	
	#if (flash || nme)
	public static var stage(default, null):flash.display.Stage = null;
	public static var root(default, null):flash.display.Sprite = null;
	#if flash11
	public static var stage3d:flash.display.Stage3D = null;
	public static var numDeviceLost = -1;
	#if flash11_4
	public static var profile = flash.display3D.Context3DProfile.BASELINE;
	#end
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
	
	public static function create(onCreate:Void->Void, onResize:Int->Int->Void = null, args:SurfaceArgs = null)
	{
		_onCreate = function()
		{
			L.i('surface initialized (${width}x${height})');
			_flags |= READY;
			onCreate();
		}
		
		RenderSurface.onResize = onResize;
		
		bound = new AABB2();
		bound.minX = 0;
		bound.minY = 0;
		
		_mouse = new Vec2();
		
		#if flash
		if (args != null)
		{
			if (args.hasField('hardware') && args.hardware)
				_flags |= HARDWARE;
				
			#if flash11_4
			if (args.hasField('profile') && args.hardware)
				profile = args.field('profile');
			#end
		}
		
		L.d('context 3d profile is $profile');
		
		initDisplayList();
		#elseif cpp
		#if nme
		initDisplayList();
		#else
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
				((isHardware() ? 1 : 0) * nme.Lib.HARDWARE) | 1 * nme.Lib.RESIZABLE);
		}
		catch (error:Dynamic)
		{
			//nme.Lib.create already called
			initDisplayList();
		}
		#end
		#elseif js
		_tmp = new Vec2();
		_jq = new js.JQuery(js.Lib.window).ready(
			function (_)
			{
				_canvas = cast js.Lib.document.getElementById(args.canvasId);
				
				context = _canvas.getContext('2d');
				if (isResizable())
				{
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
		#if flash
		//remove all display objects in a bottom(=leaf)->up fashion
		var a:Array<flash.display.DisplayObject> = [];
		function rec(x:flash.display.DisplayObject)
		{
			if (Std.is(x, flash.display.DisplayObjectContainer))
			{
				var o:flash.display.DisplayObjectContainer = cast x;
				for (i in 0...o.numChildren) rec(o.getChildAt(i));
			}
			a.push(x);
		}
		rec(flash.Lib.current.stage);
		for (i in a) i.parent.removeChild(i);


		#if flash11
		if (isHardware())
		{
			try 
			{
				stage3d.removeEventListener(flash.events.Event.CONTEXT3D_CREATE, function(e) _onCreate());
			}
			catch(error:Dynamic) {}
		}
		#end
		#end
		
		_flags &= ~READY;
	}
	
	#if (flash || nme)
	static function initDisplayList():Void
	{
		stage = flash.Lib.current.stage;
		root = new flash.display.Sprite();
		root.mouseEnabled = false;
		root.name = 'root';
		root.addEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);
		flash.Lib.current.addChild(root);
	}
	
	static function onAddedToStage(e):Void
	{
		cast(e.target, flash.display.Sprite).removeEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);
		
		bound.maxX = width = stage.stageWidth;
		bound.maxY = height = stage.stageHeight;
		
		#if (flash || nme)
		stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		stage.align = flash.display.StageAlign.TOP_LEFT;
		stage.addEventListener(flash.events.Event.RESIZE, onStageResize);
		#end
		
		if (isHardware())
		{
			#if flash11
			initStage3d();
			return;
			#end
		}
		
		_onCreate();
	}
	#end
	
	#if flash11
	static function initStage3d():Void
	{
		stage = flash.Lib.current.stage;
		stage3d = flash.Lib.current.stage.stage3Ds[0];
		stage3d.addEventListener(flash.events.Event.CONTEXT3D_CREATE, onContext3DCreate);
		
		#if flash11_4
		stage3d.requestContext3D(cast flash.display3D.Context3DRenderMode.AUTO, profile);
		#else
		stage3d.requestContext3D(cast flash.display3D.Context3DRenderMode.AUTO);
		#end
	}
	
	static function onContext3DCreate(_):Void
	{
		if (++numDeviceLost == 0)
			_onCreate();
	}
	#end
	
	static function onStageResize(_):Void
	{
		#if (flash || nme)
		bound.maxX = width = stage.stageWidth;
		bound.maxY = height = stage.stageHeight;
		#end
		
		L.i('surface resized to ${width}x${height}');
		if (onResize != null) onResize(width, height);
	}
}