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
package de.polygonal.zz.scene;

import de.polygonal.ds.ArrayedStack;
import de.polygonal.ds.ArrayUtil;

typedef GlobalStateStacks = Array<ArrayedStack<GlobalState>>;

class GlobalState
{
	static var _stacks:GlobalStateStacks = null;
	static var _numStates:Int;
	
	inline public static function getStacks():GlobalStateStacks
	{
		if (_stacks == null) initStacks();
		return _stacks;
	}
	
	public static function clrStacks()
	{
		for (i in 0..._numStates)
			_stacks[i].clear();
	}
	
	public static function dumpStacks():String
	{
		var s = "";
		for (i in 0..._numStates)
			s += '[$i] => [${_stacks[i].toArray().join("")}]';
		return s;
	}
	
	static function initStacks()
	{
		_numStates = Type.getEnumConstructs(GlobalStateType).length;
		_stacks = ArrayUtil.alloc(_numStates);
		for (i in 0..._numStates) _stacks[i] = new ArrayedStack();
	}
	
	public var type(default, null):GlobalStateType;
	public var index(default, null):Int;
	public var flags(default, null):Int;
	public var enabled:Bool;
	public var next:GlobalState;
	
	public var __alphaState:AlphaState;
	
	public function new(type:GlobalStateType)
	{
		this.type = type;
		this.index = Type.enumIndex(type);
		flags = 1 << index;
		enabled = true;
		next = null;
	}
	
	inline public function equals(other:GlobalState):Bool
		return flags == other.flags;
}