package de.polygonal.zz.render.module;

#if flash11
import de.polygonal.zz.render.module.flash.stage3d.Stage3dAntiAliasMode;
#end

typedef RenderModuleConfig =
{
	#if flash
	?container:flash.display.DisplayObjectContainer,
	#end
	
	#if flash11
	?preferConstantOverVertexBatching:Bool,
	?textureFlags:Int,
	?enableErrorChecking:Bool,
	?antiAliasMode:Stage3dAntiAliasMode,
	#end
	
	?width:Int,
	?height:Int,
	?maxBatchSize:Int,
}