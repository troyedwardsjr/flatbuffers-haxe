package flatbuffers.impl;

import cpp.Pointer;

extern class FlatBuffersCpp {
}

@:include("flatbuffers/flatbuffers.h")
@:structAccess
@:unreflective
@:native("flatbuffers::FlatBufferBuilder")
extern class BuilderCpp {
	@:native("new flatbuffers::FlatBufferBuilder") 
	public static function create():Pointer<BuilderCpp>;

	@:native("Clear") 
	public function clear():Void;

	@:native("CreateSharedString") 
	@:overload(function(str:String):OffsetString { })
	public function createSharedString(str:String, ?size_t:Int) : OffsetString;
	
	@:native("CreateString") 
	@:overload(function(str:String):OffsetString { })
	public function createString(str:String, ?size_t:Int) : OffsetString;

	@:native("CreateVector") 
	public function createVector(v:Dynamic) : OffsetVector;

	@:native("DedupVtables") 
	public function dedupVtables(dedup:Bool) : Void;

	@:native("Finish") 
	public function finish(a:Dynamic) : Void;
	
	@:native("GetBufferPointer") 
	public function getBufferPointer() : Pointer<cpp.UInt8>;

	@:native("GetSize") 
	public function getSize() : Int;
}

@:include("flatbuffers/flatbuffers.h")
extern class Offset<T> { 
   	@:native("IsNull") public function isNull():Bool;
		@:native("Offset") public function offset(uoffset_t_o:Dynamic):Bool;
		@:native("Union") public function union():OffsetVoid;
}

@:structAccess
@:native("flatbuffers::Offset<flatbuffers::String>")
extern class OffsetString extends Offset<String> { 
	
}

@:structAccess
@:native("flatbuffers::Offset<void>")
extern class OffsetVoid extends Offset<Void> { 
	
}

@:structAccess
@:unreflective
@:native("flatbuffers::Offset<flatbuffers::Vector<flatbuffers::soffset_t>>")
extern class OffsetVector extends Offset<String>{
}

