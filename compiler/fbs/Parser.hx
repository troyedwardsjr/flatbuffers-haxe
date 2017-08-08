package fbs;

import fbs.Token;
import fbs.Ast;

class Parser extends hxparse.Parser<hxparse.LexerTokenSource<FbsToken>, FbsToken> implements hxparse.ParserBuilder {

	var moduleName:String;
	var parsedObject:Dynamic = {
		namespaces: [],
		enums: [],
		unions: [],
		structs: [],
		tables: [],
		roottypes: []
	};

	public function new(input:byte.ByteData, sourceName:String) {
		moduleName = sourceName;
		super(new hxparse.LexerTokenSource(new fbs.Lexer(input, sourceName), fbs.Lexer.tok));
	}

	// Parse FlatBuffer IDL.
	public function parse():{} {
		while(true) {
			switch stream {
				case [{def: TComment(s)}]:
				case [{def: TKeyword(FbsNamespace)}, ns = namespace([])]:
					parsedObject.namespaces.push(ns);
				case [{def: TKeyword(FbsEnum)}, en = enumParse(null)]:
					parsedObject.enums.push(en);
				case [{def: TKeyword(FbsUnion)}, un = unionParse()]:
					parsedObject.unions.push(un);
				case [{def: TKeyword(FbsStruct)}]:
				case [{def: TKeyword(FbsTable)}]:
				case [{def: TKeyword(FbsRootType)}]:
				case _:
					trace(this.peek(0).def);
					junk();
					break;
			}
		}
		return parsedObject;
	}


	function namespace(arr:Array<String>):Array<String> {
		while (true) {
			switch stream {
				case [{def: TSemicolon}]: break;
				case [{def: TDot}]: 
				case [{def: TIdent(s)}]: arr.push(s);
			}
		}
		return arr;
	}


	// Enums

	function enumParse(decl:FbsDeclaration):FbsDeclaration {
		while (true) {
			switch stream {
				case [{def: TRBrace}]: break;
				case [{def: TIdent(s)}, {def: TColon}, t = type(), {def: TLBrace}, props = enumProps([])]: 

				decl = DEnum({
					name: s, 
					type: t,
					constructors: props
				});
				trace(decl.getParameters()[0].constructors);
				break;
				
				case _: break;
			}
		}
		return decl;
	}

	function enumProps(arr:Array<FbsEnumCtor>):Array<FbsEnumCtor> {
		while (true) {
			switch stream {
				case [{def: TIdent(s)}, val = enumNext()]: 
				arr.push({
					name: TIdentifier(s),
					value: val
				});
				case _: break;
			}
		}
		return arr;
	}

	function enumNext() {
		return switch stream {
			case [{def: TAssign}, {def: TNumber(n)}, {def: TComma | TRBrace}]: n;
			case [{def: TComma}]: "";
		} 
	}


	// Unions
	function unionParse() {
		while (true) {
			switch stream {
				//case [{def: TSemicolon}]: break;
				case [{def: TIdent(s)}, {def: TLBrace}, {def: TIdent(i)}, {def: TRBrace}]: 
				trace(s);
				trace(i);
			}
		}
		return "arr";
	}

	// Utils

	function type():FbsType {
		return switch stream {
			case [{def: TIdent("byte")}]: TPredefined(TByte);
			case [{def: TIdent("ubyte")}]: TPredefined(TUByte);
		}
	}
	
}