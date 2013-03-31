package de.polygonal.zz;

#if log
class L
{
	static var _log:de.polygonal.core.log.Log;
	static function log():de.polygonal.core.log.Log
	{
		if (_log == null) _log = de.polygonal.core.log.LogSystem.createLog('zz', true);
		return _log;
	}
	
	inline public static function d(msg:String, ?tag:String, ?posInfos:haxe.PosInfos):Void log().d(msg, tag, posInfos);
	inline public static function i(msg:String, ?tag:String, ?posInfos:haxe.PosInfos):Void log().i(msg, tag, posInfos);
	inline public static function w(msg:String, ?tag:String, ?posInfos:haxe.PosInfos):Void log().w(msg, tag, posInfos);
	inline public static function e(msg:String, ?tag:String, ?posInfos:haxe.PosInfos):Void log().e(msg, tag, posInfos);
}
#else
class L
{
	inline public static function d(x:String, ?tag:String):Void {}
	inline public static function i(x:String, ?tag:String):Void {}
	inline public static function w(x:String, ?tag:String):Void {}
	inline public static function e(x:String, ?tag:String):Void {}
}
#end