
package fbs;

enum FbsPrimitiveType {
	TBool;
	TByte;
	TUByte;
	TShort;
	TUShort;
	TInt;
	TUInt;
	TFloat;
	TLong;
	TULong;
	TDouble;
	TString;
}

enum FbsType {
	TPrimitive(t:FbsPrimitiveType);
	TComposite(t:String);
}

enum FbsPropertyName {
	TIdentifier(s:String);
	TStringLiteral(s:String);
	TNumericLiteral(s:String);
}

typedef FbsEnum = {
	name: String,
	type: FbsType,
	ctors: Array<FbsEnumCtor>
}

typedef FbsEnumCtor = {
	name: FbsPropertyName,
	value: Null<String>
}

typedef FbsUnion = {
	name: String,
	values: Array<String>
}
typedef FbsStruct = {
	name: String,
	fields: Array<FbsStructFields>
}

typedef FbsStructFields = {
	key: String,
	type: FbsType
}

typedef FbsTable = {
	name: String,
	fields: Array<FbsTableFields>
}

typedef FbsTableFields = {
	key: String,
	type: Array<FbsType>,
	defaultValue: Null<String>
}

enum FbsDeclaration {
	DNamespace(ns:Array<String>);
	DEnum(en:FbsEnum);
	DUnion(un:FbsUnion);
	DStruct(str:FbsStruct);
	DTable(tb:FbsTable);
	DRootType(rt:Array<String>);
}