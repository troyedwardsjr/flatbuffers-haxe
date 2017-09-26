package fbs;

import fbs.Token;
import fbs.Ast;

typedef ParsedObject = {
	namespaces: Array<FbsDeclaration>,
	enums: Array<FbsDeclaration>,
	unions: Array<FbsDeclaration>,
	structs: Array<FbsDeclaration>,
	tables: Array<FbsDeclaration>,
	rootTypes: Array<FbsDeclaration>
}

class Parser extends hxparse.Parser<hxparse.LexerTokenSource<FbsToken>, FbsToken> implements hxparse.ParserBuilder {

	var moduleName:String;
	var parsedObject:ParsedObject = {
		namespaces: [],
		enums: [],
		unions: [],
		structs: [],
		tables: [],
		rootTypes: []
	};

	public function new(input:byte.ByteData, sourceName:String) {
		moduleName = sourceName;
		super(new hxparse.LexerTokenSource(new fbs.Lexer(input, sourceName), fbs.Lexer.tok));
	}

	// Parse FlatBuffer IDL.
	public function parse():ParsedObject {
		while(true) {
			switch stream {
				case [{def: TComment(s)}]:
				case [{def: TKeyword(FbsNamespace)}, ns = namespaceParse([])]:
					parsedObject.namespaces.push(ns);
				case [{def: TKeyword(FbsEnum)}, en = enumParse(null)]:
					parsedObject.enums.push(en);
				case [{def: TKeyword(FbsUnion)}, un = unionParse(null)]:
					parsedObject.unions.push(un);
				case [{def: TKeyword(FbsStruct)}, str = structParse(null)]:
					parsedObject.structs.push(str);
				case [{def: TKeyword(FbsTable)}, tb = tableParse(null)]:
					parsedObject.tables.push(tb);
				case [{def: TIdent("root_type")}, rt = rootTypeParse([])]:
					parsedObject.rootTypes.push(rt);
				case [{def: TEof}]:
					break;
				case _:
					trace(this.peek(0).def);
					junk();
					break;
			}
		}
		return parsedObject;
	}

	// Namespace

	function namespaceParse(arr:Array<String>):FbsDeclaration {
		while (true) {
			switch stream {
				case [{def: TSemicolon}]: break;
				case [{def: TDot}]: 
				case [{def: TIdent(s)}]: arr.push(s);
			}
		}
		return DNamespace(arr);
	}


	// Enums

	function enumParse(decl:FbsDeclaration):FbsDeclaration {
		while (true) {
			switch stream {
				case [{def: TIdent(s)}, {def: TColon}, t = type(), {def: TLBrace}, props = enumProps([])]:
					decl = DEnum({
						name: s, 
						type: t,
						ctors: props
					});	
					this.last.def == TRBrace ? break : continue;
			}
		}
		return decl;
	}
	
	function enumProps(arr:Array<FbsEnumCtor>):Array<FbsEnumCtor> {
		var enumIndex:Int = 0;
		while (true) {
			switch stream {
				case [{def: TIdent(s)}, val = enumNext(enumIndex)]: 
					arr.push({
						name: TIdentifier(s),
						value: val
					});
					this.last.def == TRBrace ? break : continue;
			}
		}
		return arr;
	}

	function enumNext(enumIndex:Int):String {
		return switch stream {
			case [{def: TAssign}, {def: TNumber(v)}, close = enumClose(enumIndex)]: v;
			case [close = enumClose(enumIndex)]: close;
		} 
	}

	function enumClose(enumIndex:Int):String {
		return switch stream {
			case [{def: TRBrace}]: enumIndex++; Std.string(enumIndex);
			case [{def: TComma}]: enumIndex++; Std.string(enumIndex);
		} 
	}


	// Unions

	function unionParse(decl:FbsDeclaration) {
		while (true) {
			switch stream {
				case [{def: TIdent(s)}, {def: TLBrace}, val = unionNext([])]: 
					
				decl = DUnion({
					name: s, 
					values: val
				});
				break;
			}
		}
		return decl;
	}

	function unionNext(arr:Array<String>):Array<String> {
		while (true) {
			switch stream {
				case [{def: TRBrace}]: break;
				case [{def: TIdent(s)}]: arr.push(s);
				case [{def: TComma}]: 
			}
		}
		return arr;
	}

	// Structs

	function structParse(decl:FbsDeclaration):FbsDeclaration {
		while (true) {
			switch stream {
				case [{def: TIdent(s)}, {def: TLBrace}, f = structFields([])]:
				decl = DStruct({
					name: s, 
					fields: f
				}); 
				break;
			}
		}
		return decl;
	}

	function structFields(arr:Array<FbsStructField>):Array<FbsStructField> {
		while (true) {
			switch stream {
				case [{def: TRBrace}]: break;
				case [{def: TComment(s)}]:
				case [{def: TIdent(s)}, {def: TColon}, t = type(), {def: TSemicolon}]: 
					arr.push({
						name: s,
						type: t
					});
			}
		}
		return arr;
	}
	

	// Tables

	function tableParse(decl:FbsDeclaration):FbsDeclaration {
		while (true) {
			switch stream {
				case [{def: TRBrace}]: break;
				case [{def: TIdent(s)}, {def: TLBrace}, f = tableFields([])]:
					decl = DTable({
						name: s, 
						fields: f
					}); 
					break;
			}
		}
		return decl;
	}

	function tableFields(arr:Array<FbsTableField>):Array<FbsTableField> {
		while (true) {
			switch stream {
				case [{def: TRBrace}]: break;
				case [{def: TComment(s)}]:
				case [{def: TIdent(s)}, {def: TColon}, t = typeVector([]), tn = tableNext()]: 
					arr.push({
						name: s,
						type: t,
						defaultValue: tn
					});
			}
		}
		return arr;
	}

	function tableNext():String {
		return switch stream {
			// Replace semicolon with while loop switch stream for attributes then semicolon or
			// simply semicolon with no attributes.
			case [{def: TSemicolon}]: null;
			case [{def: TAssign}, {def: TNumber(v) | TBool(v) | TIdent(v)}, {def: TSemicolon}]: v;
		}
	}

	// Root Type

	function rootTypeParse(arr:Array<String>):FbsDeclaration {
		while (true) {
			switch stream {
				case [{def: TSemicolon}]: break;
				case [{def: TIdent(s)}]: arr.push(s);
			}
		}
		return DRootType(arr);
	}

	// Utils

	function type():FbsType {
		return switch stream {
			case [{def: TIdent("bool")}]: TPrimitive(TBool);
			case [{def: TIdent("byte")}]: TPrimitive(TByte);
			case [{def: TIdent("ubyte")}]: TPrimitive(TUByte);
			case [{def: TIdent("short")}]: TPrimitive(TShort);
			case [{def: TIdent("ushort")}]: TPrimitive(TUShort);
			case [{def: TIdent("int")}]: TPrimitive(TInt);
			case [{def: TIdent("uint")}]: TPrimitive(TUInt);
			case [{def: TIdent("float")}]: TPrimitive(TFloat);
			case [{def: TIdent("long")}]: TPrimitive(TLong);
			case [{def: TIdent("ulong")}]: TPrimitive(TULong);
			case [{def: TIdent("double")}]: TPrimitive(TDouble);
			case [{def: TIdent("string")}]: TPrimitive(TString);
			case [{def: TIdent(s)}]: TComposite(s);
		}
	}

	function typeVector(arr:Array<FbsType>):Array<FbsType> {
		return switch stream {
			case [{def: TLBrack}, t = typeNext(arr)]: arr = t;
			case [t = type()]: [t]; 
		}
	}

	function typeNext(arr:Array<FbsType>):Array<FbsType> {
		while (true) {
			switch stream {
				case [t = type()]: arr.push(t);
				case [{def: TRBrack}]: break;
			}
		}
		return arr;
	}

}