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

import de.polygonal.core.sys.Entity;
import de.polygonal.core.sys.EntityPriority;
import haxe.ds.StringMap;

class AniPlayback extends Entity
{
	public var curAnimationId(default, null):String;
	
	var _sequenceMap:StringMap<AniSequence>;
	var _curSequence:AniSequence;
	var _time = 0.;
	
	public function new()
	{
		super();
		priority = EntityPriority.ANIMATION;
		_curSequence = null;
		_sequenceMap = new StringMap();
		tick = false;
	}
	
	inline public function getFrame():AniFrame
	{
		return _curSequence == null ? null : _curSequence.getFrameAtTime(_time);
	}
	
	inline public function isFinished():Bool
	{
		var s = _curSequence;
		return s != null && !s.loop && _time >= s.length && s.frameCount > 1;
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
			L.w('animation "$id" does not exist');
		if (_curSequence != sequence)
		{
			curAnimationId = id;
			_curSequence = sequence;
			if (resetTime) _time = 0;
			tick = true;
		}
	}
	
	public function stopAnimation():Void
	{
		_curSequence = null;
		tick = false;
	}
	
	override function onFree():Void
	{
		_sequenceMap = null;
		_curSequence = null;
	}
	
	override function onTick(timeDelta:Float, parent:Entity):Void
	{
		if (_curSequence != null)
			_time += timeDelta;
	}
}