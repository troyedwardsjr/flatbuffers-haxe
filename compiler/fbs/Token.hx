package fbs;

enum FbsKeyword {
	FbsNamespace;
	FbsEnum;
	FbsUnion;
	FbsStruct;
	FbsTable;
	FbsRootType;
}

enum FbsTokenDef {
	TLPar;
	TRPar;
	TLBrack;
	TRBrack;
	TLBrace;
	TRBrace;
	TLt;
	TGt;
	TColon;
	TSemicolon;
	TComma;
	TEquals;
	TAssign;
	TArrow;
	TQuestion;
	TEllipsis;
	TDot;
	TPipe;
	TKeyword(kwd:FbsKeyword);
	TIdent(s:String);
	TString(s:String);
	TNumber(s:String);
	TComment(s:String);
	TEof;
	TObject;
	TCircular;
}

class FbsToken {
	public var def: FbsTokenDef;
	public var pos: hxparse.Position;

	public function new(tok, pos) {
		this.def = tok;
		this.pos = pos;
	}
}