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
package de.polygonal.zz.api.animation;

import de.polygonal.ds.ArrayUtil;
import de.polygonal.core.util.Assert;

class AniSequence
{
	public var id:String;
	public var loop(default, null):Bool;
	public var length(default, null):Float;
	public var frameCount(default, null):Int;
	
	var _lastFrameIndex:Int;
	var _frames:Array<AniFrame>;
	var _startTimes:Array<Float>;

	public function new(id:String, loop:Bool)
	{
		this.id = id;
		this.loop = loop;
		length = 0;
		frameCount = 0;
		
		_lastFrameIndex = 0;
		_frames = new Array<AniFrame>();
		_startTimes = new Array<Float>();
	}
	
	public function free():Void
	{
		_frames = null;
		_startTimes = null;
	}
	
	public function addFrame(frame:AniFrame):Void
	{
		_startTimes[frameCount] = length;
		_frames.push(frame);
		frameCount++;
		_lastFrameIndex = 0;
		
		length += frame.duration;
	}
	
	inline public function getFrameIndex():Int
	{
		return _lastFrameIndex;
	}
	
	inline public function getFrameAtIndex(i:Int):AniFrame
	{
		#if debug
		D.assert(i >= 0 && i < _frames.length, 'i >= 0 && i < _frames.length');
		#end
		
		return _frames[i];
	}
	
	public function getFrameAtTime(time:Float):AniFrame
	{
		if (length == .0) return null;
		
		if (frameCount == 1) return _frames[0];
		if (!loop && time >= length) return _frames[_lastFrameIndex = (frameCount - 1)];
		
		var cycleTime = loop ? (time % length) : time;
		
		var newIndex = 0;
		
		//exploit temporal coherence by checking passed time since last invocation
		var t0 = _startTimes[_lastFrameIndex];
		var t1 = _startTimes[_lastFrameIndex + 1];
		if (cycleTime >= t0 && cycleTime <= t1)
			newIndex = _lastFrameIndex;
		else
		{
			if (frameCount < 16)
			{
				//perform sequential search
				var currentTime = .0;
				for (i in 0...frameCount)
				{
					currentTime += _frames[i].duration;
					if (currentTime > cycleTime)
					{
						newIndex = i;
						break;
					}
				}
			}
			else
			{
				//perform binary search
				newIndex = ArrayUtil.bsearchFloat(_startTimes, cycleTime, 0, frameCount - 1);
				if (newIndex < 0)
				{
					newIndex = ~newIndex;
					newIndex--;
				}
			}
		}
		
		return _frames[_lastFrameIndex = newIndex];
	}
}