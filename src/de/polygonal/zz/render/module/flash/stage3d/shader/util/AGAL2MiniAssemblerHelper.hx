package de.polygonal.zz.render.module.flash.stage3d.shader.util;

import flash.utils.RegExp;
import haxe.ds.StringMap;

class AgalMiniAssemblerHelper
{
	static var regExpCache:StringMap<RegExp> = new StringMap<RegExp>();
	
	inline public static function replace(s:String, pattern:String, ?flags = '', x:String):String
	{
		return untyped s.replace(getRegExp(pattern, flags), x);
	}
	
	inline public static function search(s:String, pattern:String, ?flags = ''):Int
	{
		return untyped s.search(getRegExp(pattern, flags));
	}
	
	inline public static function match(s:String, pattern:String, ?flags = ''):Array<String>
	{
		return untyped s.match(getRegExp(pattern, flags));
	}
	
	inline public static function slice(s:String, start:Int, end = 0x7fffffff):String
	{
		return untyped s.slice(start, end == 0x7fffffff ? s.length : end);
	}
	
	inline static function getRegExp(pattern:String, flags:String)
	{
		var regExp = regExpCache.get(pattern + flags);
		if (regExp == null)
		{
			regExp = new flash.utils.RegExp(pattern, flags);
			regExpCache.set(pattern + flags, regExp);
		}
		return regExp;
	}
}