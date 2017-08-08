
package fbs;

enum FbsPredefinedType {
	TByte;
	TUByte;
	TBool;
	TShort;
	TUShort;
	TInt;
	TUInt;
	TFloat;
	TLong;
	TULong;
	TDouble;
}

enum FbsType {
	TPredefined(t:FbsPredefinedType);
}

enum FbsPropertyName {
	TIdentifier(s:String);
	TStringLiteral(s:String);
	TNumericLiteral(s:String);
}

typedef FbsEnum = {
	name: String,
	type: FbsType,
	constructors: Array<FbsEnumCtor>
}

typedef FbsEnumCtor = {
	name: FbsPropertyName,
	value: Null<String>
}

enum FbsDeclaration {
	DEnum(en:FbsEnum);
}