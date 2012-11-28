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
package de.polygonal.zz.scene;

import de.polygonal.core.fmt.Sprintf;
import de.polygonal.ds.ArrayedStack;

typedef GlobalStateStacks = Array<ArrayedStack<GlobalState>>;

class GlobalState
{
	static var _stacks:GlobalStateStacks = null;
	inline public static function getStacks():GlobalStateStacks
	{
		if (_stacks == null)
		{
			_stacks = new Array();
			for (i in 0...Type.getEnumConstructs(GlobalStateType).length)
				_stacks[i] = new ArrayedStack();
		}
		return _stacks;
	}
	
	public static function clearStacks():Void
	{
		for (i in _stacks) i.clear();
	}
	
	public static function dumpStacks():String
	{
		var s = '\n';
		for (i in 0...Type.getEnumConstructs(GlobalStateType).length)
			s += Sprintf.format("[%d] => [%s]\n", [i, _stacks[i].toArray().join('')]);
		return s;
	}
	
	public var type(default, null):GlobalStateType;
	
	public var index(default, null):Int;
	public var enabled:Bool;
	public var next:GlobalState;
	
	public var __alphaState:AlphaState;
	
	public function new(type:GlobalStateType)
	{
		this.type = type;
		this.index = Type.enumIndex(type);
		enabled = true;
		next = null;
	}
}