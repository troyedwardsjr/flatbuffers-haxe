package flatbuffers.impl;

import haxe.Int32;
import haxe.Int64;
import haxe.ds.Either;
import haxe.io.UInt8Array;
import haxe.io.UInt16Array;
import haxe.io.Int32Array;
import haxe.io.Float32Array;
import haxe.io.Float64Array;

typedef Offset = Int;

typedef TableT = {
	bb: ByteBuffer,
	bb_pos: Int
}

typedef EncodingT = {
	UTF8_BYTES: Int,
  UTF16_STRING: Int
}

class FlatBuffersPure 
{
	public static inline var SIZEOF_SHORT:Int = 2;
	public static inline var SIZEOF_INT:Int = 4;
	public static inline var FILE_IDENTIFIER_LENGTH:Int = 4;
	public static var Encoding:EncodingT = { UTF8_BYTES: 1, UTF16_STRING: 2 };
	public static var int32:Int32Array = new Int32Array(2);
	// TODO: Look at this cast again.
	public static var float32:Float32Array = Float32Array.fromData(cast FlatBuffersPure.int32.view);
	public static var float64:Float64Array = Float64Array.fromData(cast FlatBuffersPure.int32.view);
	public static var isLittleEndian:Bool = UInt16Array.fromData(cast UInt8Array.fromArray([1, 0]).view)[0] == 1;
}

class Builder
{
	private var bb:ByteBuffer;
	private var initial_size:Int;
	private var space:Int;
	private var minalign:Int;
	private var vtable:Array<Int>;
	private var vtable_in_use:Int;
	private var isNested:Bool;
	private var object_start:Int;
	private var vtables:Array<Int>;
	private var vector_num_elems:Int;
	private var force_defaults:Bool;

	public function new(opt_initial_size:Int)
	{
		if (opt_initial_size == null) {
			initial_size = 1024;
		} else {
			initial_size = opt_initial_size;
		}

		this.bb = ByteBuffer.allocate(initial_size);
		this.space = initial_size;
		this.minalign = 1;
		this.vtable = null;
  	this.vtable_in_use = 0;
		this.isNested = false;
		this.object_start = 0;
		this.vtables = [];
		this.vector_num_elems = 0;
		this.force_defaults = false;
	}

	public function forceDefaults(forceDefaults:Bool):Void 
	{
		this.force_defaults = forceDefaults;
	}

	public function dataBuffer():ByteBuffer
	{
		return this.bb;
	}
	
	public function asUint8Array():UInt8Array
	{
		return this.bb.bytes().subarray(this.bb.position(), this.bb.position() + this.offset());
	}

	public function prep(size:Int, additional_bytes:Int):Void
	{
		// Track the biggest thing we've ever aligned to.
		if (size > this.minalign) {
			this.minalign = size;
		}

		// Find the amount of alignment needed such that `size` is properly
		// aligned after `additional_bytes`
		var align_size = ((~(this.bb.capacity() - this.space + additional_bytes)) + 1) & (size - 1);

		// Reallocate the buffer if needed.
		while (this.space < align_size + size + additional_bytes) {
			var old_buf_size = this.bb.capacity();
			this.bb = this.growByteBuffer(this.bb);
			this.space += this.bb.capacity() - old_buf_size;
		}

		this.pad(align_size);
	}

	public function pad(byte_size):Void
	{
		for (i in 0...byte_size) {
			this.bb.writeInt8(--this.space, 0);
		}
	}

	public function writeInt8(value:Int):Void
	{
		this.bb.writeInt8(this.space -= 1, value);
	}

	public function writeInt16(value:Int):Void
	{
		this.bb.writeInt16(this.space -= 2, value);
	}

	public function writeInt32(value:Int):Void
	{
		this.bb.writeInt32(this.space -= 4, value);
	}

	public function writeInt64(value:Long):Void
	{
		this.bb.writeInt64(this.space -= 8, value);
	}

	public function writeFloat32(value:Float):Void
	{
		this.bb.writeFloat32(this.space -= 4, value);
	}

	public function writeFloat64(value:Float):Void
	{
		this.bb.writeFloat64(this.space -= 8, value);
	}

	public function addInt8(value:Int):Void
	{
		this.prep(1, 0);
  	this.writeInt8(value);
	}

	public function addInt16(value:Int):Void
	{
		this.prep(2, 0);
  	this.writeInt16(value);
	}

	public function addInt32(value:Int):Void
	{
		this.prep(4, 0);
  	this.writeInt32(value);
	}

	public function addInt64(value:Long):Void
	{
		this.prep(8, 0);
  	this.writeInt64(value);
	}

	public function addFloat32(value:Float):Void
	{
		this.prep(4, 0);
  	this.writeFloat32(value);
	}

	public function addFloat64(value:Float):Void
	{
		this.prep(8, 0);
  	this.writeFloat64(value);
	}

	public function addFieldInt8(voffset:Int, value:Int, defaultValue:Int):Void
	{
		if (this.force_defaults || value != defaultValue) {
			this.addInt8(value);
			this.slot(voffset);
		}
	}

	public function addFieldInt16(voffset:Int, value:Int, defaultValue:Int):Void
	{
		if (this.force_defaults || value != defaultValue) {
			this.addInt16(value);
			this.slot(voffset);
		}
	}

	public function addFieldInt32(voffset:Int, value:Int, defaultValue:Int):Void
	{
		if (this.force_defaults || value != defaultValue) {
			this.addInt32(value);
			this.slot(voffset);
		}
	}

	public function addFieldInt64(voffset:Int, value:Long, defaultValue:Long):Void
	{
		if (this.force_defaults || value != defaultValue) {
			this.addInt64(value);
			this.slot(voffset);
		}
	}

	public function addFieldFloat32(voffset:Int, value:Float, defaultValue:Float):Void
	{
		if (this.force_defaults || value != defaultValue) {
			this.addFloat32(value);
			this.slot(voffset);
		}
	}

	public function addFieldFloat64(voffset:Int, value:Float, defaultValue:Float):Void
	{
		if (this.force_defaults || value != defaultValue) {
			this.addFloat64(value);
			this.slot(voffset);
		}
	}

	public function addFieldOffset(voffset:Int, value:Offset, defaultValue:Offset):Void
	{
		if (value != defaultValue) {
			this.nested(value);
			this.slot(voffset);
		}
	}

	public function addFieldStruct(voffset:Int, value:Offset, defaultValue:Offset):Void
	{
		if (value != defaultValue) {
			this.nested(value);
			this.slot(voffset);
		}
	}
	
	public function nested(obj:Offset):Void
	{
		//TODO
		//if (obj != this.offset()) {
		//	throw "FlatBuffers: struct must be serialized inline.";
		//}
	}

	public function notNested():Void
	{
		if (this.isNested) {
			throw "FlatBuffers: object serialization must not be nested.";
		}
	}

	public function slot(voffset:Int):Void
	{
		this.vtable[voffset] = this.offset();
	}

	public function offset():Offset
	{
		return this.bb.capacity() - this.space;
	}

	public function growByteBuffer(bb:ByteBuffer):ByteBuffer
	{
		var old_buf_size = bb.capacity();

		// Ensure we don't grow beyond what fits in an int.
		if ((old_buf_size & 0xC0000000) != null) {
			throw "FlatBuffers: cannot grow buffer beyond 2 gigabytes.";
		}

		var new_buf_size = old_buf_size << 1;
		var nbb = ByteBuffer.allocate(new_buf_size);
		nbb.setPosition(new_buf_size - old_buf_size);

		var index:Int = new_buf_size - old_buf_size;
		for(i in 0...bb.bytes().length) {
			nbb.bytes().set(index, bb.bytes().get(i));
			index++;
		}
		
		return nbb;
	}

	public function addOffset(offset:Offset):Void 
	{
		this.prep(FlatBuffersPure.SIZEOF_INT, 0); // Ensure alignment is already done.
  	this.writeInt32(this.offset() - offset + FlatBuffersPure.SIZEOF_INT);
	}

	public function startObject(numfields:Int):Void
	{
		this.notNested();
		if (this.vtable == null) {
			this.vtable = [];
		}
		this.vtable_in_use = numfields;
		for (i in 0...numfields) {
			this.vtable[i] = 0; // This will push additional elements as needed
		}
		this.isNested = true;
		this.object_start = this.offset();
	}

	public function endObject():Offset
	{
		if (this.vtable == null || !this.isNested) {
			throw "FlatBuffers: endObject called without startObject";
		}

		this.addInt32(0);
		var vtableloc = this.offset();

		// Trim trailing zeroes.
		var i = this.vtable_in_use - 1;
		while(i >= 0 && this.vtable[i] != null) {i--;}
		var trimmed_size = i + 1;

		// Write out the current vtable.
		while (i >= 0) {
			// Offset relative to the start of the table.
			this.addInt16(this.vtable[i] != 0 ? vtableloc - this.vtable[i] : 0);
			i--;
		}

		var standard_fields = 2; // The fields below:
		this.addInt16(vtableloc - this.object_start);
		var len = (trimmed_size + standard_fields) * FlatBuffersPure.SIZEOF_SHORT;
		this.addInt16(len);

		// Search for an existing vtable that matches the current one.
		var existing_vtable = 0;
		var vt1 = this.space;

		//TODO: outer loop.
		for (i in 0...this.vtables.length) {
			var vt2 = this.bb.capacity() - this.vtables[i];
			if (len == this.bb.readInt16(vt2)) {
					var j:Int = FlatBuffersPure.SIZEOF_SHORT;
					while(j < len) {
							if (this.bb.readInt16(vt1 + j) != this.bb.readInt16(vt2 + j)) {
								j += FlatBuffersPure.SIZEOF_SHORT;
								continue;
							}
						
						existing_vtable = this.vtables[i];
						break;
					}
			}
		}
		

		if (existing_vtable != null) {
			// Found a match:
			// Remove the current vtable.
			this.space = this.bb.capacity() - vtableloc;

			// Point table to existing vtable.
			this.bb.writeInt32(this.space, existing_vtable - vtableloc);
		} else {
			// No match:
			// Add the location of the current vtable to the list of vtables.
			this.vtables.push(this.offset());

			// Point table to current vtable.
			this.bb.writeInt32(this.bb.capacity() - vtableloc, this.offset() - vtableloc);
		}

		this.isNested = false;
		return vtableloc;
	}

	public function finish(root_table:Offset, ?opt_file_identifier:String):Void
	{
		if (opt_file_identifier != null) {
			var file_identifier = opt_file_identifier;
			this.prep(this.minalign, FlatBuffersPure.SIZEOF_INT +
				FlatBuffersPure.FILE_IDENTIFIER_LENGTH);
			if (file_identifier.length != FlatBuffersPure.FILE_IDENTIFIER_LENGTH) {
				throw "FlatBuffers: file identifier must be length" +
					Std.string(FlatBuffersPure.FILE_IDENTIFIER_LENGTH);
			}
			var i = FlatBuffersPure.FILE_IDENTIFIER_LENGTH - 1;
			while(i >= 0)
			{
				this.writeInt8(file_identifier.charCodeAt(i));
				i--;
			}
		}
		this.prep(this.minalign, FlatBuffersPure.SIZEOF_INT);
		this.addOffset(root_table);
		this.bb.setPosition(this.space);
	}

	public function requiredField(table:Offset, field:Int):Void{
		var table_start = this.bb.capacity() - table;
		var vtable_start = table_start - this.bb.readInt32(table_start);
		var ok = this.bb.readInt16(vtable_start + field) != 0;

		// If this fails, the caller will show what field needs to be set.
		if (!ok) {
			throw "FlatBuffers: field ' + field + ' must be set";
		}
	}

	public function startVector(elem_size:Int, num_elems:Int, alignment:Int):Void
	{
		this.notNested();
		this.vector_num_elems = num_elems;
		this.prep(FlatBuffersPure.SIZEOF_INT, elem_size * num_elems);
		this.prep(alignment, elem_size * num_elems); // Just in case alignment > int.
	}

	public function endVector():Offset
	{
		this.writeInt32(this.vector_num_elems);
  	return this.offset();
	}

	public function createString(s:Either<UInt8Array, String>):Offset
	{
		var utf8:UInt8Array;
		switch(s) {
			case Left(s): 
				utf8 = s;
			case Right(s):
				//TODO: Possibly redo later.
				var tempArray:Array<Int> = [];
				var i = 0;

				while (i < s.length) {
					var codePoint;

					// Decode UTF-16
					var a = s.charCodeAt(i++);
					if (a < 0xD800 || a >= 0xDC00) {
						codePoint = a;
					} else {
						var b = s.charCodeAt(i++);
						codePoint = (a << 10) + b + (0x10000 - (0xD800 << 10) - 0xDC00);
					}

					// Encode UTF-8
					if (codePoint < 0x80) {
						tempArray.push(codePoint);
					} else {
						if (codePoint < 0x800) {
							tempArray.push(((codePoint >> 6) & 0x1F) | 0xC0);
						} else {
							if (codePoint < 0x10000) {
								tempArray.push(((codePoint >> 12) & 0x0F) | 0xE0);
							} else {
								tempArray.push(((codePoint >> 18) & 0x07) | 0xF0);
								tempArray.push(((codePoint >> 12) & 0x3F) | 0x80);
							}
							tempArray.push(((codePoint >> 6) & 0x3F) | 0x80);
						}
						tempArray.push((codePoint & 0x3F) | 0x80);
					}
				}
				utf8 = UInt8Array.fromArray(tempArray);
		}

		this.addInt8(0);
		this.startVector(1, utf8.length, 1);
		this.bb.setPosition(this.space -= utf8.length);

		var i = 0, offset = this.space, bytes = this.bb.bytes();
		while(i < utf8.length)
		{
			bytes[offset++] = utf8[i];
			i++;
		}
		return this.endVector();
	}

	public function createLong(low:Int, high:Int):Long
	{
		return Long.create(low, high);
	}

}

class ByteBuffer
{
	private var bytes_:UInt8Array;
	private var position_:Int;

	public function new(bytes:UInt8Array) {
		this.bytes_ = bytes;
		this.position_ = 0;
	}

	public static function allocate(byte_size:Int):ByteBuffer
	{
		return new ByteBuffer(new UInt8Array(byte_size));
	}

	public function bytes():UInt8Array
	{
		return this.bytes_;
	}

	public function position():Int
	{
		return this.position_;
	}

	public function setPosition(position:Int):Int
	{
		return this.position_ = position;
	}

	public function capacity():Int
	{
		return this.bytes_.length;
	}

	public function readInt8(offset:Int):Int
	{
		return this.readUint8(offset) << 24 >> 24;
	}

	public function readUint8(offset:Int):Int
	{
		return this.bytes_[offset];
	}

	public function readInt16(offset:Int):Int
	{
		return this.readUint16(offset) << 16 >> 16;
	}

	public function readUint16(offset:Int):Int
	{
		return this.bytes_[offset] | this.bytes_[offset + 1] << 8;
	}

	public function readInt32(offset:Int):Int
	{
		return this.bytes_[offset] | this.bytes_[offset + 1] << 8 | this.bytes_[offset + 2] << 16 | this.bytes_[offset + 3] << 24;
	}

	public function readUint32(offset:Int):Int
	{
		return this.readInt32(offset) >>> 0;
	}
	
	public function readInt64(offset:Int):Long
	{
		return new Long(this.readInt32(offset), this.readInt32(offset + 4));
	}

	public function readUint64(offset:Int):Long
	{
		return new Long(this.readUint32(offset), this.readUint32(offset + 4));
	}

	public function readFloat32(offset:Int):Float
	{
		FlatBuffersPure.int32[0] = this.readInt32(offset);
  	return FlatBuffersPure.float32[0];
	}

	public function readFloat64(offset:Int):Float
	{
		FlatBuffersPure.int32[FlatBuffersPure.isLittleEndian ? 0 : 1] = this.readInt32(offset);
		FlatBuffersPure.int32[FlatBuffersPure.isLittleEndian ? 1 : 0] = this.readInt32(offset + 4);
		return FlatBuffersPure.float64[0];
	}

	public function writeInt8(offset:Int, value:Int):Void
	{
		this.bytes_[offset] = value;
	}

	public function writeUint8(offset:Int, value:Int):Void
	{
		this.bytes_[offset] = value;
	}

	public function writeInt16(offset:Int, value:Int):Void
	{
		this.bytes_[offset] = value;
  	this.bytes_[offset + 1] = value >> 8;
	}

	public function writeInt32(offset:Int, value:Int):Void
	{
		this.bytes_[offset] = value;
  	this.bytes_[offset + 1] = value >> 8;
	}

	public function writeUint32(offset:Int, value:Int):Void
	{
		this.bytes_[offset] = value;
    this.bytes_[offset + 1] = value >> 8;
    this.bytes_[offset + 2] = value >> 16;
    this.bytes_[offset + 3] = value >> 24;
	}

	public function writeInt64(offset:Int, value:Long):Void
	{
		this.writeInt32(offset, value.low);
  	this.writeInt32(offset + 4, value.high);
	}

	public function writeUint64(offset:Int, value:Long):Void
	{
		this.writeUint32(offset, value.low);
    this.writeUint32(offset + 4, value.high);
	}
	
	public function writeFloat32(offset:Int, value:Float):Void
	{
		FlatBuffersPure.float32[0] = value;
  	this.writeInt32(offset, FlatBuffersPure.int32[0]);
	}

	public function writeFloat64(offset:Int, value:Float):Void
	{
		FlatBuffersPure.float64[0] = value;
		this.writeInt32(offset, FlatBuffersPure.int32[FlatBuffersPure.isLittleEndian ? 0 : 1]);
		this.writeInt32(offset + 4, FlatBuffersPure.int32[FlatBuffersPure.isLittleEndian ? 1 : 0]);
	}

	public function __offset(bb_pos:Int, vtable_offset:Int):Int
	{
		var vtable = bb_pos - this.readInt32(bb_pos);
  	return vtable_offset < this.readInt16(vtable) ? this.readInt16(vtable + vtable_offset) : 0;
	}

	public function __union(t:TableT, offset:Int):TableT
	{
		t.bb_pos = offset + this.readInt32(offset);
		t.bb = this;
		return t;
	}

	public function __string(offset:Int, opt_encoding:Int):Either<String, UInt8Array>
	{
		offset += this.readInt32(offset);

		var length:Int = this.readInt32(offset);
		var result:String = '';
		var i:Int = 0;

		offset += FlatBuffersPure.SIZEOF_INT;

		if (opt_encoding == FlatBuffersPure.Encoding.UTF8_BYTES) {
			return Right(this.bytes_.subarray(offset, offset + length));
		}

		while (i < length) {
			var codePoint;

			// Decode UTF-8
			var a = this.readUint8(offset + i++);
			if (a < 0xC0) {
				codePoint = a;
			} else {
				var b = this.readUint8(offset + i++);
				if (a < 0xE0) {
					codePoint =
						((a & 0x1F) << 6) |
						(b & 0x3F);
				} else {
					var c = this.readUint8(offset + i++);
					if (a < 0xF0) {
						codePoint =
							((a & 0x0F) << 12) |
							((b & 0x3F) << 6) |
							(c & 0x3F);
					} else {
						var d = this.readUint8(offset + i++);
						codePoint =
							((a & 0x07) << 18) |
							((b & 0x3F) << 12) |
							((c & 0x3F) << 6) |
							(d & 0x3F);
					}
				}
			}

			// Encode UTF-16
			if (codePoint < 0x10000) {
				result += String.fromCharCode(codePoint);
			} else {
				codePoint -= 0x10000;
				result += String.fromCharCode((codePoint >> 10) + 0xD800) + 
				String.fromCharCode((codePoint & ((1 << 10) - 1)) + 0xDC00);
			}
		}
		//TODO: Look at this return again.
		return Left(result);
	}

	public function __indirect(offset:Int):Int
	{
		return offset + this.readInt32(offset);
	}

	public function __vector(offset:Int):Int
	{
		return offset + this.readInt32(offset) + FlatBuffersPure.SIZEOF_INT; // data starts after the length
	}

	public function __vector_len(offset:Int):Int
	{
		return this.readInt32(offset + this.readInt32(offset));
	}

	public function __has_identifier(ident:String):Bool
	{
		if (ident.length != FlatBuffersPure.FILE_IDENTIFIER_LENGTH) {
			throw "FlatBuffers: file identifier must be length." + Std.string(FlatBuffersPure.FILE_IDENTIFIER_LENGTH);
		}
		for (i in 0...FlatBuffersPure.FILE_IDENTIFIER_LENGTH) {
			if (ident.charCodeAt(i) != this.readInt8(this.position_ + FlatBuffersPure.SIZEOF_INT + i)) {
				return false;
			}
		}
		return true;
	}

	public function createLong(low:Int, high:Int):Long
	{
		return Long.create(low, high);
	}

}

//TODO: Possibly extend Int64
class Long 
{
	public static var ZERO:Long = new Long(0, 0);

	public var low:Int;
	public var high:Int;
	
	public function new(low:Int, high:Int)
	{
		this.low = low;
		this.high = high;
	}

	public static function create(low, high):Long
	{
		return low == 0 && high == 0 ? ZERO : new Long(low, high);
	}

	public function toFloat64():Float
	{
		//return (this.low >>> 0) + this.high * 0x100000000);
		return 0.0;
	}

	public function equals(other:Long):Bool
	{
		return this.low == other.low && this.high == other.high;
	}

}