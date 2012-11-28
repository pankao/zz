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
// ================================================================================
//
//	ADOBE SYSTEMS INCORPORATED
//	Copyright 2010 Adobe Systems Incorporated
//	All Rights Reserved.
//
//	NOTICE: Adobe permits you to use, modify, and distribute this file
//	in accordance with the terms of the license agreement accompanying it.
//
// ================================================================================
package de.polygonal.zz.render.flash.stage3d.shader.util;

class AGALMiniAssembler
{
	static var OPMAP                        = new flash.utils.Dictionary();
	static var REGMAP                       = new flash.utils.Dictionary();
	static var SAMPLEMAP                    = new flash.utils.Dictionary();
	inline static var MAX_NESTING           = 4;
	inline static var MAX_OPCODES           = 256;
	inline static var SAMPLER_DIM_SHIFT     = 12;
	inline static var SAMPLER_SPECIAL_SHIFT = 16;
	inline static var SAMPLER_REPEAT_SHIFT  = 20;
	inline static var SAMPLER_MIPMAP_SHIFT  = 24;
	inline static var SAMPLER_FILTER_SHIFT  = 28;
	inline static var REG_WRITE             = 0x1;
	inline static var REG_READ              = 0x2;
	inline static var REG_FRAG              = 0x20;
	inline static var REG_VERT              = 0x40;
	inline static var OP_SCALAR             = 0x1;
	inline static var OP_INC_NEST           = 0x2;
	inline static var OP_DEC_NEST           = 0x4;
	inline static var OP_SPECIAL_TEX        = 0x8;
	inline static var OP_SPECIAL_MATRIX     = 0x10;
	inline static var OP_FRAG_ONLY          = 0x20;
	inline static var OP_VERT_ONLY          = 0x40;
	inline static var OP_NO_DEST            = 0x80;
	inline static var MOV                   = 'mov';
	inline static var ADD                   = 'add';
	inline static var SUB                   = 'sub';
	inline static var MUL                   = 'mul';
	inline static var DIV                   = 'div';
	inline static var RCP                   = 'rcp';
	inline static var MIN                   = 'min';
	inline static var MAX                   = 'max';
	inline static var FRC                   = 'frc';
	inline static var SQT                   = 'sqt';
	inline static var RSQ                   = 'rsq';
	inline static var POW                   = 'pow';
	inline static var LOG                   = 'log';
	inline static var EXP                   = 'exp';
	inline static var NRM                   = 'nrm';
	inline static var SIN                   = 'sin';
	inline static var COS                   = 'cos';
	inline static var CRS                   = 'crs';
	inline static var DP3                   = 'dp3';
	inline static var DP4                   = 'dp4';
	inline static var ABS                   = 'abs';
	inline static var NEG                   = 'neg';
	inline static var SAT                   = 'sat';
	inline static var M33                   = 'm33';
	inline static var Mat44                 = 'm44';
	inline static var M34                   = 'm34';
	inline static var IFZ                   = 'ifz';
	inline static var INZ                   = 'inz';
	inline static var IFE                   = 'ife';
	inline static var INE                   = 'ine';
	inline static var IFG                   = 'ifg';
	inline static var IFL                   = 'ifl';
	inline static var IEG                   = 'ieg';
	inline static var IEL                   = 'iel';
	inline static var ELS                   = 'els';
	inline static var EIF                   = 'eif';
	inline static var REP                   = 'rep';
	inline static var ERP                   = 'erp';
	inline static var BRK                   = 'brk';
	inline static var KIL                   = 'kil';
	inline static var TEX                   = 'tex';
	inline static var SGE                   = 'sge';
	inline static var SLT                   = 'slt';
	inline static var SGN                   = 'sgn';
	inline static var VA                    = 'va';
	inline static var VC                    = 'vc';
	inline static var VT                    = 'vt';
	inline static var OP                    = 'op';
	inline static var V                     = 'v';
	inline static var FC                    = 'fc';
	inline static var FT                    = 'ft';
	inline static var FS                    = 'fs';
	inline static var OC                    = 'oc';
	inline static var D2                    = '2d';
	inline static var D3                    = '3d';
	inline static var CUBE                  = 'cube';
	inline static var MIPNEAREST            = 'mipnearest';
	inline static var MIPLINEAR             = 'miplinear';
	inline static var MIPNONE               = 'mipnone';
	inline static var NOMIP                 = 'nomip';
	inline static var NEAREST               = 'nearest';
	inline static var LINEAR                = 'linear';
	inline static var CENTROID              = 'centroid';
	inline static var SINGLE                = 'single';
	inline static var DEPTH                 = 'depth';
	inline static var REPEAT                = 'repeat';
	inline static var WRAP                  = 'wrap';
	inline static var CLAMP                 = 'clamp';
	
	public var error(default, null):String;
	public var agalcode(default, null):flash.utils.ByteArray;
	
	var debugEnabled:Bool;
	
	static var initialized = false;

	public function new(debugging = false)
	{
		error = '';
		agalcode = null;
		debugEnabled = false;
		debugEnabled = debugging;
		if (!initialized) init();
	}

	public function assemble(mode:flash.display3D.Context3DProgramType, source:String, verbose = false):flash.utils.ByteArray
	{
		var start = flash.Lib.getTimer();
		agalcode = new flash.utils.ByteArray();
		error = '';
		
		var isFrag = false;
		if (mode == flash.display3D.Context3DProgramType.FRAGMENT)
			isFrag = true;
		else
		if (mode != flash.display3D.Context3DProgramType.VERTEX)
			error = 'ERROR: mode needs to be \'' + flash.display3D.Context3DProgramType.FRAGMENT + '\' or \'' + flash.display3D.Context3DProgramType.VERTEX + '\' but is \'' + mode + '\'.';
		
		agalcode.endian = flash.utils.Endian.LITTLE_ENDIAN;
		agalcode.writeByte(0xa0);
		agalcode.writeUnsignedInt(0x1);
		agalcode.writeByte(0xa1);
		agalcode.writeByte(isFrag ? 1 : 0);
		
		var lines:Array<String> = untyped source.replace(new flash.utils.RegExp('[\\f\\n\\r\\v]+', 'g'), '\n').split('\n');
		
		var nest = 0;
		var nops = 0;
		var i = 0;
		var k = 0;
		var lng = lines.length;
		while (i < lng && error == '')
		{
			var line = lines[i];
			var startcomment = line.indexOf('//');
			if (startcomment != -1) line = slice(line, 0, startcomment);
			
			var optsi = untyped line.search(new flash.utils.RegExp('<.*>', 'g'));
			var opts = null;
			if (optsi != -1)
			{
				opts = match(slice(line, optsi), '([\\w\\.\\-\\+]+)', 'gi');
				line = slice(line, 0, optsi);
			}
			
			//find opcode
			var opCode = match(line, '^\\w{3}', 'ig');
			var opFound:OpCode = untyped OPMAP[opCode[0]];
			
			//if debug is enabled, output the opcodes
			if (debugEnabled) trace(opFound);
			
			if (opFound == null)
			{
				if (line.length >= 3) trace('warning: bad line ' + i + ': ' + lines[i]);
				{
					i++;
					continue;
				}
			}
			
			line = slice(line, line.indexOf(opFound.name) + opFound.name.length);
			
			if (opFound.flags & OP_DEC_NEST > 0)
			{
				nest--;
				if (nest < 0)
				{
					error = 'error: conditional closes without open.';
					break;
				}
			}
			if (opFound.flags & OP_INC_NEST > 0)
			{
				nest++;
				if (nest > MAX_NESTING)
				{
					error = 'error: nesting to deep, maximum allowed is ' + MAX_NESTING + '.';
					break;
				}
			}
			if ((opFound.flags & OP_FRAG_ONLY > 0) && !isFrag)
			{
				error = 'error: opcode is only allowed in fragment programs.';
				break;
			}
			if (verbose) trace('emit opcode=' + opFound);
			
			agalcode.writeUnsignedInt(opFound.emitCode);
			
			nops++;
			
			if (nops > MAX_OPCODES)
			{
				error = 'error: too many opcodes. maximum is ' + MAX_OPCODES + '.';
				break;
			}
			
			var regs = match(line, 'vc\\[([vof][actps]?)(\\d*)?(\\.[xyzw](\\+\\d{1,3})?)?\\](\\.[xyzw]{1,4})?|([vof][actps]?)(\\d*)?(\\.[xyzw]{1,4})?', 'gi');
			if (regs.length != opFound.numRegister)
			{
				error = 'error: wrong number of operands. found ' + regs.length + ' but expected ' + opFound.numRegister + '.';
				break;
			}
			
			var badreg = false;
			var pad = 64 + 64 + 32;
			var regLength = regs.length;
			var j = 0;
			while (j < regLength)
			{
				var isRelative = false;
				var relreg = match(regs[j], '\\[.*\\]', 'ig');
				if (relreg.length > 0)
				{
					regs[j] = StringTools.replace(regs[j], relreg[0], '0');
					
					if (verbose) trace('IS REL');
					isRelative = true;
				}
				
				var res = match(regs[j], '^\\b[A-Za-z]{1,2}', 'ig');
				var regFound:Register = untyped REGMAP[res[0]];
				
				if (debugEnabled) trace(regFound);
				
				if (regFound == null)
				{
					error = 'error: could not parse operand ' + j + ' (' + regs[j] + ').';
					badreg = true;
					break;
				}
				
				if (isFrag)
				{
					if (!(regFound.flags & REG_FRAG > 0))
					{
						error = 'error: register operand ' + j + ' (' + regs[j] + ') only allowed in vertex programs.';
						badreg = true;
						break;
					}
					
					if (isRelative)
					{
						error = 'error: register operand ' + j + ' (' + regs[j] + ') relative adressing not allowed in fragment programs.';
						badreg = true;
						break;
					}
				}
				else
				{
					if (!(regFound.flags & REG_VERT > 0))
					{
						error = 'error: register operand ' + j + ' (' + regs[j] + ') only allowed in fragment programs.';
						badreg = true;
						break;
					}
				}
				
				regs[j] = slice(regs[j], regs[j].indexOf(regFound.name) + regFound.name.length);
				
				var idxmatch = (isRelative) ? match(relreg[0], '\\d+') : match(regs[j], '\\d+');
				var regidx = 0;
				if (idxmatch != null)
				{
					regidx = Std.parseInt(idxmatch[0]);
				}
				
				if (regFound.range < regidx)
				{
					error = 'error: register operand ' + j + ' (' + regs[j] + ') index exceeds limit of ' + (regFound.range + 1) + '.';
					badreg = true;
					break;
				}
				
				var regmask:UInt = 0;
				var maskmatch = match(regs[j], '(\\.[xyzw]{1,4})');
				var isDest = (j == 0 && !(opFound.flags & OP_NO_DEST > 0));
				var isSampler = (j == 2 && (opFound.flags & OP_SPECIAL_TEX > 0));
				var reltype = 0;
				var relsel = 0;
				var reloffset = 0;
				if (isDest && isRelative)
				{
					error = 'error: relative can not be destination';
					badreg = true;
					break;
				}
				
				if (maskmatch != null)
				{
					regmask = 0;
					var cv:UInt = 0;
					var maskLength = maskmatch[0].length;
					k = 1;
					while (k < maskLength)
					{
						cv = maskmatch[0].charCodeAt(k) - 'x'.charCodeAt(0);
						if (cv > 2) cv = 3;
						if (isDest) regmask |= 1 << cv;
						else regmask |= cv << ((k - 1) << 1);
						k++;
					}
					if (!isDest)
					{
						while (k <= 4)
						{
							regmask |= cv << ((k - 1) << 1);
							k++;
						}
					}
				}
				else
				{
					regmask = isDest ? 0xf : 0xe4;
				}

				if (isRelative)
				{
					var relname = match(relreg[0], '[A-Za-z]{1,2}', 'ig');
					var regFoundRel:Register = untyped REGMAP[relname[0]];
					if (regFoundRel == null)
					{
						error = 'error: bad index register';
						badreg = true;
						break;
					}
					reltype = regFoundRel.emitCode;
					var selmatch = match(relreg[0], '(\\.[xyzw]{1,1})', '');
					if (selmatch.length == 0)
					{
						error = 'error: bad index register select';
						badreg = true;
						break;
					}
					relsel = selmatch[0].charCodeAt(1) - 'x'.charCodeAt(0);
					if (relsel > 2) relsel = 3;
					var relofs = match(relreg[0], '\\+\\d{1,3}', 'ig');
					if (relofs.length > 0) reloffset = Std.parseInt(relofs[0]);
					if (reloffset < 0 || reloffset > 255)
					{
						error = 'error: index offset ' + reloffset + ' out of bound. [0..255]';
						badreg = true;
						break;
					}
					
					if (verbose) trace('RELATIVE: type=' + reltype + '==' + relname[0] + ' sel=' + relsel + '==' + selmatch[0] + ' idx=' + regidx + ' offset=' + reloffset);
				}
				
				if (verbose) trace('  emit argcode=' + regFound + '[' + regidx + '][' + regmask + ']');
				
				if (isDest)
				{
					agalcode.writeShort(regidx);
					agalcode.writeByte(regmask);
					agalcode.writeByte(regFound.emitCode);
					pad -= 32;
				}
				else
				{
					if (isSampler)
					{
						if (verbose) trace('  emit sampler');
						var samplerbits = 5;
						//type 5
						var optsLength = opts.length;
						var bias = 0.;
						k = 0;
						while (k < optsLength)
						{
							if (verbose) trace('    opt: ' + opts[k]);
							var optfound:Sampler = untyped SAMPLEMAP[opts[k]];
							if (optfound == null)
							{
								bias = Std.parseFloat(opts[k]);
								if (verbose) trace('    bias: ' + bias);
							}
							else
							{
								if (optfound.flag != SAMPLER_SPECIAL_SHIFT) samplerbits &= ~(0xf << optfound.flag);
								samplerbits |= optfound.mask << optfound.flag;
							}
							k++;
						}
						agalcode.writeShort(regidx);
						agalcode.writeByte(Std.int(bias * 8.0));
						agalcode.writeByte(0);
						agalcode.writeUnsignedInt(samplerbits);
						
						if (verbose) trace('    bits: ' + (samplerbits - 5));
						pad -= 64;
					}
					else
					{
						if (j == 0)
						{
							agalcode.writeUnsignedInt(0);
							pad -= 32;
						}
						agalcode.writeShort(regidx);
						agalcode.writeByte(reloffset);
						agalcode.writeByte(regmask);
						agalcode.writeByte(regFound.emitCode);
						agalcode.writeByte(reltype);
						agalcode.writeShort((isRelative) ? (relsel | (1 << 15)):0);
						pad -= 64;
					}
				}
				j++;
			}
			
			//pad unused regs
			j = 0;
			while (j < Std.int(pad))
			{
				agalcode.writeByte(0);
				j += 8;
			}
			if (badreg) break;
			i++;
		}
		
		if (error != '')
		{
			error += 'at line ' + i + ' ' + lines[i];
			agalcode.length = 0;
			trace(error);
		}
		
		if (debugEnabled)
		{
			var dbgLine = 'generated bytecode:';
			var agalLength = Std.int(agalcode.length);
			var index = 0;
			while (index < agalLength)
			{
				if (!(index % 16 > 0)) dbgLine += '\n';
				if (!(index % 4 > 0)) dbgLine += ' ';
				var byteStr:String = StringTools.hex(agalcode[index]).toLowerCase();
				if (byteStr.length < 2) byteStr = '0' + byteStr;
				dbgLine += byteStr;
				index++;
			}
			trace(dbgLine);
		}
		
		if (verbose) trace('AGALMiniAssembler.assemble time: ' + ((flash.Lib.getTimer() - start) / 1000) + 's');
		agalcode.position = 0;
		return agalcode;
	}
	
	inline static function match(s:String, pattern:String, ?flags = ''):Array<String> return untyped s.match(new flash.utils.RegExp(pattern, flags))
	inline static function slice(s:String, start:Int, end = 0x7fffffff):String return untyped s.slice(start, end == 0x7fffffff ? s.length : end)
	
	static function init()
	{
		initialized = true;
		untyped
		{
			OPMAP[MOV]            = new OpCode(MOV, 2, 0x00, 0);
			OPMAP[ADD]            = new OpCode(ADD, 3, 0x01, 0);
			OPMAP[SUB]            = new OpCode(SUB, 3, 0x02, 0);
			OPMAP[MUL]            = new OpCode(MUL, 3, 0x03, 0);
			OPMAP[DIV]            = new OpCode(DIV, 3, 0x04, 0);
			OPMAP[RCP]            = new OpCode(RCP, 2, 0x05, 0);
			OPMAP[MIN]            = new OpCode(MIN, 3, 0x06, 0);
			OPMAP[MAX]            = new OpCode(MAX, 3, 0x07, 0);
			OPMAP[FRC]            = new OpCode(FRC, 2, 0x08, 0);
			OPMAP[SQT]            = new OpCode(SQT, 2, 0x09, 0);
			OPMAP[RSQ]            = new OpCode(RSQ, 2, 0x0a, 0);
			OPMAP[POW]            = new OpCode(POW, 3, 0x0b, 0);
			OPMAP[LOG]            = new OpCode(LOG, 2, 0x0c, 0);
			OPMAP[EXP]            = new OpCode(EXP, 2, 0x0d, 0);
			OPMAP[NRM]            = new OpCode(NRM, 2, 0x0e, 0);
			OPMAP[SIN]            = new OpCode(SIN, 2, 0x0f, 0);
			OPMAP[COS]            = new OpCode(COS, 2, 0x10, 0);
			OPMAP[CRS]            = new OpCode(CRS, 3, 0x11, 0);
			OPMAP[DP3]            = new OpCode(DP3, 3, 0x12, 0);
			OPMAP[DP4]            = new OpCode(DP4, 3, 0x13, 0);
			OPMAP[ABS]            = new OpCode(ABS, 2, 0x14, 0);
			OPMAP[NEG]            = new OpCode(NEG, 2, 0x15, 0);
			OPMAP[SAT]            = new OpCode(SAT, 2, 0x16, 0);
			OPMAP[M33]            = new OpCode(M33, 3, 0x17, OP_SPECIAL_MATRIX);
			OPMAP[Mat44]          = new OpCode(Mat44, 3, 0x18, OP_SPECIAL_MATRIX);
			OPMAP[M34]            = new OpCode(M34, 3, 0x19, OP_SPECIAL_MATRIX);
			OPMAP[IFZ]            = new OpCode(IFZ, 1, 0x1a, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
			OPMAP[INZ]            = new OpCode(INZ, 1, 0x1b, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
			OPMAP[IFE]            = new OpCode(IFE, 2, 0x1c, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
			OPMAP[INE]            = new OpCode(INE, 2, 0x1d, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
			OPMAP[IFG]            = new OpCode(IFG, 2, 0x1e, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
			OPMAP[IFL]            = new OpCode(IFL, 2, 0x1f, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
			OPMAP[IEG]            = new OpCode(IEG, 2, 0x20, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
			OPMAP[IEL]            = new OpCode(IEL, 2, 0x21, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
			OPMAP[ELS]            = new OpCode(ELS, 0, 0x22, OP_NO_DEST | OP_INC_NEST | OP_DEC_NEST);
			OPMAP[EIF]            = new OpCode(EIF, 0, 0x23, OP_NO_DEST | OP_DEC_NEST);
			OPMAP[REP]            = new OpCode(REP, 1, 0x24, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
			OPMAP[ERP]            = new OpCode(ERP, 0, 0x25, OP_NO_DEST | OP_DEC_NEST);
			OPMAP[BRK]            = new OpCode(BRK, 0, 0x26, OP_NO_DEST);
			OPMAP[KIL]            = new OpCode(KIL, 1, 0x27, OP_NO_DEST | OP_FRAG_ONLY);
			OPMAP[TEX]            = new OpCode(TEX, 3, 0x28, OP_FRAG_ONLY | OP_SPECIAL_TEX);
			OPMAP[SGE]            = new OpCode(SGE, 3, 0x29, 0);
			OPMAP[SLT]            = new OpCode(SLT, 3, 0x2a, 0);
			OPMAP[SGN]            = new OpCode(SGN, 2, 0x2b, 0);
			REGMAP[VA]            = new Register(VA, 'vertex attribute', 0x0, 7, REG_VERT | REG_READ);
			REGMAP[VC]            = new Register(VC, 'vertex constant', 0x1, 127, REG_VERT | REG_READ);
			REGMAP[VT]            = new Register(VT, 'vertex temporary', 0x2, 7, REG_VERT | REG_WRITE | REG_READ);
			REGMAP[OP]            = new Register(OP, 'vertex output', 0x3, 0, REG_VERT | REG_WRITE);
			REGMAP[V]             = new Register(V, 'varying', 0x4, 7, REG_VERT | REG_FRAG | REG_READ | REG_WRITE);
			REGMAP[FC]            = new Register(FC, 'fragment constant', 0x1, 27, REG_FRAG | REG_READ);
			REGMAP[FT]            = new Register(FT, 'fragment temporary', 0x2, 7, REG_FRAG | REG_WRITE | REG_READ);
			REGMAP[FS]            = new Register(FS, 'texture sampler', 0x5, 7, REG_FRAG | REG_READ);
			REGMAP[OC]            = new Register(OC, 'fragment output', 0x3, 0, REG_FRAG | REG_WRITE);
			SAMPLEMAP[D2]         = new Sampler(D2, SAMPLER_DIM_SHIFT, 0);
			SAMPLEMAP[D3]         = new Sampler(D3, SAMPLER_DIM_SHIFT, 2);
			SAMPLEMAP[CUBE]       = new Sampler(CUBE, SAMPLER_DIM_SHIFT, 1);
			SAMPLEMAP[MIPNEAREST] = new Sampler(MIPNEAREST, SAMPLER_MIPMAP_SHIFT, 1);
			SAMPLEMAP[MIPLINEAR]  = new Sampler(MIPLINEAR, SAMPLER_MIPMAP_SHIFT, 2);
			SAMPLEMAP[MIPNONE]    = new Sampler(MIPNONE, SAMPLER_MIPMAP_SHIFT, 0);
			SAMPLEMAP[NOMIP]      = new Sampler(NOMIP, SAMPLER_MIPMAP_SHIFT, 0);
			SAMPLEMAP[NEAREST]    = new Sampler(NEAREST, SAMPLER_FILTER_SHIFT, 0);
			SAMPLEMAP[LINEAR]     = new Sampler(LINEAR, SAMPLER_FILTER_SHIFT, 1);
			SAMPLEMAP[CENTROID]   = new Sampler(CENTROID, SAMPLER_SPECIAL_SHIFT, 1 << 0);
			SAMPLEMAP[SINGLE]     = new Sampler(SINGLE, SAMPLER_SPECIAL_SHIFT, 1 << 1);
			SAMPLEMAP[DEPTH]      = new Sampler(DEPTH, SAMPLER_SPECIAL_SHIFT, 1 << 2);
			SAMPLEMAP[REPEAT]     = new Sampler(REPEAT, SAMPLER_REPEAT_SHIFT, 1);
			SAMPLEMAP[WRAP]       = new Sampler(WRAP, SAMPLER_REPEAT_SHIFT, 1);
			SAMPLEMAP[CLAMP]      = new Sampler(CLAMP, SAMPLER_REPEAT_SHIFT, 0);
		}
	}
}

private class OpCode
{
	public var emitCode(default, null):Int;
	public var flags(default, null):Int;
	public var name(default, null):String;
	public var numRegister(default, null):Int;

	public function new(name:String, numRegister:Int, emitCode:Int, flags:Int)
	{
		this.name = name;
		this.numRegister = numRegister;
		this.emitCode = emitCode;
		this.flags = flags;
	}

	public function toString():String
	{
		return '[OpCode name=\'' + name + '\', numRegister=' + numRegister + ', emitCode=' + emitCode + ', flags=' + flags + ']';
	}
}

private class Register
{
	public var emitCode(default, null):Int;
	public var longName(default, null):String;
	public var name(default, null):String;
	public var flags(default, null):Int;
	public var range(default, null):Int;

	public function new(name:String, longName:String, emitCode:Int, range:Int, flags:Int)
	{
		this.name = name;
		this.longName = longName;
		this.emitCode = emitCode;
		this.range = range;
		this.flags = flags;
	}

	public function toString():String
	{
		return '[Register name=\'' + name + '\', longName=\'' + longName + '\', emitCode=' + emitCode + ', range=' + range + ', flags=' + flags + ']';
	}
}

private class Sampler
{
	public var flag(default, null):Int;
	public var mask(default, null):Int;
	public var name(default, null):String;

	public function new(name:String, flag:Int, mask:Int)
	{
		this.name = name;
		this.flag = flag;
		this.mask = mask;
	}

	public function toString():String
	{
		return '[Sampler name=\'' + name + '\', flag=\'' + flag + '\', mask=' + mask + ']';
	}
}