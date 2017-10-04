package fbs;

import fbs.Ast;
import fbs.Parser;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

using StringTools;
using Lambda;

typedef HaxeModule = {
	className: String,
	toplevel: Array<String>,
	types: Array<TypeDefinition>,
	declTypeRef: Map<String, FbsDeclaration>
}

typedef FieldType = {
	type:ComplexType, 
	alias:String,
	memSize:Int,
	defaultVal:String
};

class Converter {
	static var nullPos:Position = { min: 0, max: 0, file: "" };
	var currentModule:HaxeModule;

	public function new() {
		currentModule = {className: "", types: [], toplevel: [], declTypeRef: new Map<String, FbsDeclaration>()};
	}

	public function convert(parsedObj:ParsedObject):HaxeModule {
		storeDeclTypes(parsedObj);
		parsedObj.namespaces.map(function(decl:FbsDeclaration) {
			currentModule.toplevel.push(convertNamespace(decl));
		});
		currentModule.toplevel.push(convertImport());
		parsedObj.enums.map(function(decl:FbsDeclaration) {
			currentModule.types.push(convertEnum(decl));
		});
		parsedObj.structs.map(function(decl:FbsDeclaration) {
			currentModule.types.push(convertStruct(decl));
		});
		parsedObj.tables.map(function(decl:FbsDeclaration) {
			currentModule.types.push(convertTable(decl));
		});
		parsedObj.rootTypes.map(function(decl:FbsDeclaration) {
			currentModule.className = convertRootType(decl);
		});

		var printer:haxe.macro.Printer = new haxe.macro.Printer();
		currentModule.types.map(function(t) {
			trace(printer.printTypeDefinition(t));
		});

		return currentModule;
	}

	function storeDeclTypes(parsedObj:ParsedObject):Void {
		for(field in Reflect.fields(parsedObj)) {
			Reflect.field(parsedObj, field);
			(cast Reflect.field(parsedObj, field):Array<Dynamic>).map(function(decl:FbsDeclaration) {
				switch decl {
					case DNamespace(p):
						currentModule.declTypeRef.set(p[p.length - 1], decl);
					case DEnum(p):
						currentModule.declTypeRef.set(p.name, decl);
					case DUnion(p):
						currentModule.declTypeRef.set(p.name, decl);
					case DStruct(p):
						currentModule.declTypeRef.set(p.name, decl);
					case DTable(p):
						currentModule.declTypeRef.set(p.name, decl);
					case DRootType(p):
						currentModule.declTypeRef.set(p[p.length - 1], decl);
				}	
			});
		}
	}

	function convertImport():String
	{
		return 'import flatbuffers.FlatBuffers;\nimport flatbuffers.FlatBuffers.ByteBuffer;\nimport flatbuffers.FlatBuffers.Offset;\nimport flatbuffers.FlatBuffers.Builder;\nimport flatbuffers.FlatBuffers.Long;\nimport flatbuffers.impl.FlatBuffersPure.Encoding;\nimport flatbuffers.impl.FlatBuffersPure.TableT;\nimport haxe.Int32;\nimport haxe.Int64;\nimport haxe.io.UInt8Array;\nimport haxe.io.UInt16Array;\nimport haxe.io.Int32Array;\n#if js\nimport flatbuffers.io.Float32Array;\nimport flatbuffers.io.Float64Array;\n#else\nimport haxe.io.Float32Array;\nimport haxe.io.Float64Array;\n#end\nimport haxe.ds.Either;';
	}

	function convertNamespace(decl:FbsDeclaration):String {
		// Haxe package paths must be lower case.
		var namespace:String = (cast decl.getParameters()[0]:Array<String>).map(function(s:String) {
			return s.charAt(0).toLowerCase() + s.substr(1);
		}).join(".");
		return 'package ${namespace};';
	}

	// Convert Enums.

	function convertEnum(decl:FbsDeclaration):TypeDefinition {
		var enumObj:FbsEnum = decl.getParameters()[0];
		var fields:Array<Field> = enumObj.ctors.map(function(ctor:FbsEnumCtor):Field {
			var i:Int = 0;
			if (ctor.value != null) {
				i = Std.parseInt(ctor.value);
			}
			return {
				name: ctor.name.getParameters()[0],
				kind: FVar(null, { expr: EConst(CInt("" +i++)), pos: nullPos }),
				doc: null,
				meta: [],
				access: [],
				pos: nullPos
			}
		});
		return {
			pack: [],
			name: enumObj.name,
			pos: nullPos,
			meta: [{name: ":enum", params: [], pos: nullPos}],
			params: [],
			isExtern: false,
			kind: TDAbstract(makeType("Int")),
			fields: fields 
		}
	}

	// Convert Structs.

	function convertStruct(decl:FbsDeclaration):TypeDefinition {
		var structObj:FbsStruct = decl.getParameters()[0];
		var index = {i: 0, offset: 0};
		var funcFields:Array<Field> = structObj.fields.map(function(field:FbsStructField) {
			var fieldType:FieldType = convertType(field.type.getParameters()[0]);
			return {
				name: field.name,
				kind: FFun({
					args: [],
					ret: fieldType.type,
					expr: convertStructRet(fieldType, index),
					params: null
				}),
				doc: null,
				meta: [],
				access: [APublic],
				pos: nullPos
			}
		});
		var allFields:Array<Field> = Lambda.array(Lambda.flatten([
			makeBbVars(), 
			[makeCon()], 
			[makeInitFunc(structObj.name)],
			funcFields, 
			[convertStructCreate(structObj)]
		]));
		return {
			pack: [],
			name: structObj.name,
			pos: nullPos,
			meta: [],
			params: null,
			isExtern: false,
			kind: TDClass(null, null, false),
			fields: allFields
		};
	}

	function convertStructRet(fieldType:FieldType, index:{i: Int, offset: Int}):Expr {
		var args:Array<Expr>;
		var ident:String = "this.bb_pos";
		index.i++;
		if (index.i > 1) {
			args = [
				makeExpr(
					EBinop(
						OpAdd, 
						makeIdent(ident), 
						makeInt(Std.string(index.offset))
					) 
				)
			];
		} else {
			args = [ makeIdent(ident) ];
		}
		index.offset = index.offset + fieldType.memSize;

		return makeExpr(EReturn(
				makeExpr(EBlock([
					makeExpr(ECall(
							makeIdent('this.bb.read${fieldType.alias}'), 
							args
					))
				]))
		));	
	}

	function convertStructCreate(structObj:FbsStruct):Field {
		var args:Array<FunctionArg> = structObj.fields.map(function(field:FbsStructField) {
			var fieldType:FieldType = convertType(field.type.getParameters()[0]);
			return makeFuncArg(field.name, fieldType.type);
		});
		args.push(makeFuncArg("builder", makeType("Builder")));
		args.reverse();

		var memSizeList:Array<Int> = structObj.fields.map(function(field:FbsStructField) {
			return convertType(field.type.getParameters()[0]).memSize;
		});
		var minAlign:Int = memSizeList.fold(function(a:Int, b:Int) {
			return Std.int(Math.max(a, b));
		}, 0);
		var additional_bytes:Int = memSizeList.fold(function(a:Int, b:Int) {
			return a + b;
		}, 0);

		var expr:Array<Expr> = [];
		var byteIndex:Int = 0;

		for (i in 0...structObj.fields.length) {
			var fieldType:FieldType = convertType(structObj.fields[i].type.getParameters()[0]);
			var padding:Int = 0;
		
			if(fieldType.memSize + (byteIndex % minAlign) > minAlign) {
				padding = (Math.ceil(byteIndex / minAlign) * minAlign) - byteIndex;
				byteIndex += padding;
			}
			byteIndex += fieldType.memSize;

			// Padding.
			if(padding != 0) {
				expr.unshift(makeExpr(
					ECall(makeIdent('builder.pad'), [makeIdent(Std.string(padding))])
				));
			}
			expr.unshift(makeExpr(
				ECall(makeIdent('builder.write${fieldType.alias}'), [makeIdent(structObj.fields[i].name)])
			));

		}

		// Check if final buffer is divisible by minimum alignment (1, 2. 4 or 8), if not round up to the nearest divisible number.
		var finalSize:Int = Std.int(Math.ceil(byteIndex / minAlign) * minAlign);
		var endPadding:Int = finalSize - byteIndex;
		if(endPadding != 0) {
			expr.unshift(makeExpr(
				ECall(makeIdent('builder.pad'), [makeIdent(Std.string(endPadding))])
			));
		}

		// builder.prep();
		expr.unshift(makeExpr(
			ECall(makeIdent('builder.prep'), [makeIdent(Std.string(minAlign)), makeIdent(Std.string(finalSize))])
		));
		
		// return builder.offset();
		expr.push(makeExpr(
			EReturn(makeExpr(
				ECall(makeIdent('builder.offset'), [])
			))
		));

		return {
				name: 'create${structObj.name}',
				kind: FFun({
					args: args,
					ret: makeType('Offset'),
					expr: makeExpr(EBlock(expr)),
					params: null
				}),
				doc: null,
				meta: [],
				access: [APublic],
				pos: nullPos
		};
	}

	// Convert Unions.

	function convertUnion(decl:FbsDeclaration):TypeDefinition {
		return null;
	}

	// Convert Tables.

	function convertTable(decl:FbsDeclaration):TypeDefinition {
		var structObj:FbsTable = decl.getParameters()[0];
		var fieldsLength:Int = structObj.fields.length;
		var args:Array<FunctionArg> = [];
		var defaultRet:Expr = makeIdent('null');
		var vtable_offset:Int = 2;
		var funcFields:Array<Field> = structObj.fields.map(function(field:FbsTableField) {
			var retExpr:Expr;
			var fieldType:FieldType;
			defaultRet = makeIdent('null');
			args = [];
			switch (field.type[0]) {
				case TPrimitive(t): 
					fieldType = convertType(field.type[0].getParameters()[0]);
					switch(fieldType.alias) {
						case "String":
							fieldType.alias = "__string";
						case "Int64":
							fieldType.defaultVal = "Long.create(0, 0)";
						default:
							fieldType.alias = 'read' + fieldType.alias;
					}
					retExpr = makeExpr(EReturn(
						makeExpr(ETernary(
							makeIdent('offset != 0'), makeIdent('this.bb.${fieldType.alias}(this.bb_pos + offset)'), makeIdent(fieldType.defaultVal)
						))
					));
				case TComposite(t): 
					fieldType = {type: makeType(t), alias: t, memSize: 0, defaultVal: '0'};
					var retCall:Expr = makeIdent('(obj != null ? obj : new ${t}()).__init(this.bb_pos + offset, this.bb)');
					// Figure out type of composite by searching the current modules decleration type reference map for the type.
					switch currentModule.declTypeRef[t] {
						case DEnum(p):
							retCall = makeIdent('(this.bb.read${convertType(p.type.getParameters()[0]).alias}(this.bb_pos + offset))');
							// Maybe use unsafe cast instead of .getIndex() since it's an abstract.
							defaultRet = makeIdent('${t}.${p.ctors[0].name.getParameters()[0]}.getIndex()');
						case DUnion(p):
						case DStruct(p):
							args = [makeFuncArg("obj", makeType('Null<${t}>'))];
						case DTable(p):
							args = [makeFuncArg("obj", makeType('Null<${t}>'))];
							retCall = makeIdent('(obj != null ? obj : new ${t}()).__init(this.bb.__indirect(this.bb_pos + offset), this.bb)');
						default:
					}
					retExpr = makeExpr(EReturn(
						makeExpr(ETernary(
							makeIdent('offset != 0'), retCall, defaultRet
						))
					));
			}
			

			vtable_offset += 2;
			return {
				name: field.name,
				kind: FFun({
					args: args,
					ret: makeType('Null', null, [TPType(fieldType.type)]),
					expr: makeExpr(EBlock([
						makeExpr(makeVar(
							'offset', makeType('Null<Int>'), makeIdent('this.bb.__offset(this.bb_pos, ${vtable_offset})')
						)),
						retExpr
					])),
					params: null
				}),
				doc: null,
				meta: [],
				access: [APublic],
				pos: nullPos
			}
		});

		var funcStartFields:Field = {
			name: 'start${structObj.name}',
			kind: FFun({
				args: [makeFuncArg("builder", makeType("Builder"))],
				ret: makeType('Void'),
				expr: makeExpr(EBlock([
					makeExpr(ECall(
						makeIdent('builder.startObject'),
						[makeIdent(Std.string(fieldsLength))]
					))
				])),
				params: null
			}),
			doc: null,
			meta: [],
			access: [APublic, AStatic],
			pos: nullPos
		}
		
		var funcAddFields:List<Field> = structObj.fields.mapi(function(i:Int, field:FbsTableField) {
			var fieldType:FieldType;
			var expr:Expr;
			var fieldName:String = field.name; // Field name to have "Offset" added if needed.
			
			switch (field.type[0]) {
				case TPrimitive(t): 
					fieldType = convertType(field.type[0].getParameters()[0]);
					switch(fieldType.alias) {
						case "String":
							fieldName += "Offset";
							fieldType.alias = "Offset";
							fieldType.type = makeType("Offset");
							fieldType.defaultVal = "0";
						case "Int64":
							fieldType.defaultVal = "builder.createLong(0, 0)";
					}
					expr = makeExpr(EBlock([
						makeExpr(ECall(
							makeIdent('builder.addField${fieldType.alias}'), 
							[makeIdent(Std.string(i)), makeIdent(fieldName), makeIdent(fieldType.defaultVal)]
						))
					]));
				case TComposite(t): 
					fieldType = {type: makeType(t), alias: "Offset", memSize: 0, defaultVal: "0"};
					// Figure out type of composite by searching the current modules decleration type reference map for the type.
					switch currentModule.declTypeRef[t] {
						case DEnum(p):
							fieldType.alias = convertType(p.type.getParameters()[0]).alias;
							// Maybe use unsafe cast instead of .getIndex() since it's an abstract.
							fieldType.defaultVal = '${t}.${p.ctors[0].name.getParameters()[0]}.getIndex()';
						case DUnion(p):
						case DStruct(p):
							fieldType.type = makeType("Offset");
							fieldType.alias = "Struct";
							fieldName += "Offset";
						case DTable(p):
							fieldType.type = makeType("Offset");
							fieldName += "Offset";
						default:
					}
					expr = makeExpr(EBlock([
						makeExpr(ECall(
							makeIdent('builder.addField${fieldType.alias}'), 
							[makeIdent(Std.string(i)), makeIdent(fieldName), makeIdent(fieldType.defaultVal)]
						))
					]));
			}

			return {
				name: 'add${field.name.charAt(0).toUpperCase() + field.name.substr(1)}',
				kind: FFun({
					args: [makeFuncArg("builder", makeType("Builder")), makeFuncArg(fieldName, fieldType.type)],
					ret: makeType('Void'),
					expr: expr,
					params: null
				}),
				doc: null,
				meta: [],
				access: [APublic, AStatic],
				pos: nullPos
			}
		});
		
		var funcEndFields:Field = {
			name: 'end${structObj.name}',
			kind: FFun({
				args: [makeFuncArg("builder", makeType("Builder"))],
				ret: makeType('Offset'),
				expr: makeExpr(EBlock([
					makeExpr(makeVar(
						'offset', makeType('Null<Int>'), makeIdent('builder.endObject()')
					)),
					makeExpr(EReturn(
						makeIdent('offset')
					))
				])),
				params: null
			}),
			doc: null,
			meta: [],
			access: [APublic, AStatic],
			pos: nullPos
		}

		var allFields:Array<Field> = Lambda.array(Lambda.flatten([
			makeBbVars(),
			[makeCon()], 
			[makeInitFunc(structObj.name)],
			[convertTableGetRoot(structObj)],
			funcFields,
			[funcStartFields],
			funcAddFields,
			[funcEndFields]
		]));
		
		return {
			pack: [],
			name: structObj.name,
			pos: nullPos,
			meta: [],
			params: null,
			isExtern: false,
			kind: TDClass(null, null, false),
			fields: allFields
		};
	}

	function convertTableGetRoot(structObj:FbsTable):Field {
		return {
				name: 'getRootAs${structObj.name}',
				kind: FFun({
					args: [makeFuncArg("bb", makeType("ByteBuffer")), makeFuncArg("obj", makeType(structObj.name), true)],
					ret: makeType(structObj.name),
					expr: makeExpr(
						EBlock([
							makeExpr(EReturn(
								makeIdent('obj != null ? obj.__init(bb.readInt32(bb.position()) + bb.position(), bb) : new ${structObj.name}().__init(bb.readInt32(bb.position()) + bb.position(), bb)')
							))
						])
					),
					params: null
				}),
				doc: null,
				meta: [],
				access: [APublic, AStatic],
				pos: nullPos
		};
	}

	// Convert Root Type.

	function convertRootType(decl:FbsDeclaration):String {
		var structObj:Array<String> = decl.getParameters()[0];
		return structObj[0];
	}

	// Utils.
	function convertType(type:FbsPrimitiveType):FieldType {
		return switch(type) {
			case TBool: {type: makeType("Bool"), alias: "Int8", memSize: 1, defaultVal: "0"};// Bool/Int8
			case TByte: {type: makeType("Int"), alias: "Int8", memSize: 1, defaultVal: "0"}; // Int8
			case TUByte: {type: makeType("Int"), alias: "Int8", memSize: 1, defaultVal: "0"}; // Int8
			case TShort: {type: makeType("Int"), alias: "Int16", memSize: 2, defaultVal: "0"}; // Int16
			case TUShort: {type: makeType("Int"), alias: "Int16", memSize: 2, defaultVal: "0"}; // Int16
			case TInt: {type: makeType("Int"), alias: "Int32", memSize: 4, defaultVal: "0"}; // Int32
			case TUInt: {type: makeType("Int"), alias: "Int32", memSize: 4, defaultVal: "0"}; // Int32
			case TFloat: {type: makeType("Float"), alias: "Float32", memSize: 4, defaultVal: "0.0"}; // Float32
			case TLong: {type: makeType("Long"), alias: "Int64", memSize: 8, defaultVal: "0"}; // Int64
			case TULong: {type: makeType("Long"), alias: "Int64", memSize: 8, defaultVal: "0"}; // Int64
			case TDouble: {type: makeType("Float"), alias: "Float64", memSize: 8, defaultVal: "0.0"}; // Float64
			case TString: {type: makeType("String"), alias: "String", memSize: 8, defaultVal: "null"}; // String
		}
	}

	// Shorthand for creating expressions.
	static inline function makeExpr(exprDef:ExprDef):Expr {
		return {expr: exprDef, pos: nullPos};
	}
	// Shorthand for creating type.
	static inline function makeType(name:String, ?pack:Array<String>, ?params:Null<Array<TypeParam>> = null, ?sub:Null<Null<String>> = null):ComplexType {
		pack == null ? pack = [] : null;
		return TPath(cast { name: name, pack: pack, params: params, sub: sub });
	} 
	static inline function makeFuncArg(name:String, ?type:Null<ComplexType> = null, ?opt:Null<Bool> = null, ?meta:Null<Metadata> = null, ?value:Null<Null<Expr>> = null):FunctionArg {
		return {name: name, type: type, opt: opt, meta: meta, value: value};
	}
	static inline function makeVar(?name:Null<String> = null, ?type:Null<ComplexType> = null, ?expr:Null<Expr> = null):ExprDef {
		return EVars([{name: name, type: type, expr: expr}]);
	}

	// Shorthand for creating constants.
	static inline function makeIdent(name:String):Expr {
		return makeExpr(EConst(CIdent(name)));
	}
	static inline function makeInt(name:String):Expr {
		return makeExpr(EConst(CInt(name)));
	}
	static inline function makeFloat(name:String):Expr {
		return makeExpr(EConst(CFloat(name)));
	}
	static inline function makeString(name:String):Expr {
		return makeExpr(EConst(CString(name)));
	}

	// Shorthand for constructor.
	static inline function makeCon():Field {
		return {
				name: "new",
				kind: FFun({
					args: [],
					ret: null,
					expr: makeExpr(EBlock([])),
					params: null
				}),
				doc: null,
				meta: [],
				access: [APublic],
				pos: nullPos
		};
	}

	static inline function makeInitFunc(returnType:String):Field {
		return {
				name: "__init",
				kind: FFun({
					args: [makeFuncArg("i", makeType("Int")), makeFuncArg("bb", makeType("ByteBuffer"))],
					ret: makeType(returnType),
					expr: makeExpr(EBlock([
						makeExpr(EBinop(
							OpAssign, makeIdent("this.bb_pos"), makeIdent("i")
						)),
						makeExpr(EBinop(
							OpAssign, makeIdent("this.bb"), makeIdent("bb")
						)),
						makeExpr(EReturn(
							makeIdent("this")
						))
					])),
					params: null
				}),
				doc: null,
				meta: [],
				access: [APublic],
				pos: nullPos
		};
	}

	// Shorthand for standard ByteBuffer fields.
	static inline function makeBbVars():Array<Field> {
		return [{
				name: "bb",
				kind: FVar(makeType("ByteBuffer"), null),
				doc: null,
				meta: [],
				access: [],
				pos: nullPos
		}, {
				name: "bb_pos",
				kind: FVar(makeType("Int"), null),
				doc: null,
				meta: [],
				access: [],
				pos: nullPos
		}];
	}
	
}
