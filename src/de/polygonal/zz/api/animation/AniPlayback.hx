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
package de.polygonal.zz.api.animation;

import haxe.ds.StringMap;

class AniPlayback
{
	public var curAnimationId(default, null):String;
	
	public var curFrame(get_curFrame, never):AniFrame;
	inline function get_curFrame():AniFrame
	{
		if (_curSequence == null)
			return null;
		else
			return _curSequence.getFrameAtTime(_time);
	}
	
	public var finished(get_finished, never):Bool;
	inline function get_finished():Bool
	{
		var s = _curSequence;
		return s != null && !s.loop && _time >= s.length && s.frameCount > 1;
	}
	
	var _sequenceMap:StringMap<AniSequence>;
	var _curSequence:AniSequence;
	var _time = 0.;
	
	public function new()
	{
		_curSequence = null;
		_sequenceMap = new StringMap();
	}
	
	public function free():Void
	{
		_sequenceMap = null;
		_curSequence = null;
	}
	
	public function advance(timeDelta:Float):Void
	{
		if (_curSequence != null)
			_time += timeDelta;
	}
	
	public function addAnimation(x:AniSequence):Void
	{
		D.assert(x != null, 'x != null');
		_sequenceMap.set(x.id, x);
	}
	
	public function playAnimation(id:String, resetTime = true):Void
	{
		var sequence = _sequenceMap.get(id);
		if (sequence == null)
		{
			L.w('animation \'$id\' does not exist');
			return;
		}
		
		if (_curSequence != sequence)
		{
			curAnimationId = id;
			_curSequence = sequence;
			if (resetTime) _time = 0;
		}
	}
	
	public function stopAnimation():Void
	{
		_curSequence = null;
	}
}