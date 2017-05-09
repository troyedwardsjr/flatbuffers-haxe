package flatbuffers;

/**
 * @typedef {{
 *   bb: flatbuffers.ByteBuffer,
 *   bb_pos:Float
 * }}
 */
interface Table {
	public var bb:ByteBuffer;
	public var bb_pos:Float;
}

/**
 * @typedef {Float}
 */
typedef Offset = Float;

/**
 * @enum {Float}
 */
enum Encoding { 
	UTF8_BYTES; 
	UTF16_STRING; 
}

@:jsRequire("flatbuffers", "flatbuffers")
extern class FlatBuffers
{

  /**
   * @type {Float}
   */
  public static var SIZEOF_SHORT:Float;

  /**
   * @type {Float}
   */
  public static var SIZEOF_INT:Float;

  /**
   * @type {Float}
   */
  public static var FILE_IDENTIFIER_LENGTH:Float;

  /**
   * @type {Int32Array}
   */
  public static var int32:js.html.Int32Array;

  /**
   * @type {Float32Array}
   */
  public static var float32:js.html.Float32Array;

  /**
   * @type {Float64Array}
   */
  public static var float64:js.html.Float64Array;

  /**
   * @type {boolean}
   */
  public static var isLittleEndian:Bool;

}

////////////////////////////////////////////////////////////////////////////////

@:jsRequire("flatbuffers", "Long")
extern class Long {
	/**
	 * @type {Float}
	 * @const
	 */
	public var low:Float;

	/**
	 * @type {Float}
	 * @const
	 */
	public var high:Float;

	/**
	 * @type {flatbuffers.Long}
	 * @const
	 */
	public static var ZERO:Long;

	/**
	 * @constructor
	 * @param {Float} high
	 * @param {Float} low
	 */
	public function new(low:Float, high:Float);

	/**
	 * @returns {Float}
	 */
	public function toFloat64():Float;

	/**
	 * @param {flatbuffers.Long} other
	 * @returns {boolean}
	 */
	public function equals(other:Long):Bool; // May need to change to Dynamic.

	/**
	 * @param {Float} low
	 * @param {Float} high
	 */
	public static function create(low:Float, high:Float):Long;
}


////////////////////////////////////////////////////////////////////////////////

@:jsRequire("flatbuffers", "Builder")
extern class Builder {
	/**
	 * @constructor
	 * @param {Float=} initial_size
	 */
	public function constructor(initial_size?: Float);

	/**
	 * In order to save space, fields that are set to their default value
	 * don't get serialized into the buffer. Forcing defaults provides a
	 * way to manually disable this optimization.
	 *
	 * @param {boolean} forceDefaults true always serializes default values
	 */
	public function forceDefaults(forceDefaults: boolean):Void;

	/**
	 * Get the ByteBuffer representing the FlatBuffer. Only call this after you've
	 * called finish(). The actual data starts at the ByteBuffer's current position,
	 * not necessarily at 0.
	 *
	 * @returns {flatbuffers.ByteBuffer}
	 */
	public function dataBuffer(): ByteBuffer;

	/**
	 * Get the ByteBuffer representing the FlatBuffer. Only call this after you've
	 * called finish(). The actual data starts at the ByteBuffer's current position,
	 * not necessarily at 0.
	 *
	 * @returns {Uint8Array}
	 */
	public function asUint8Array():js.html.Uint8Array;

	/**
	 * Prepare to write an element of `size` after `additional_bytes` have been
	 * written, e.g. if you write a string, you need to align such the int length
	 * field is aligned to 4 bytes, and the string data follows it directly. If all
	 * you need to do is alignment, `additional_bytes` will be 0.
	 *
	 * @param {Float} size This is the of the new element to write
	 * @param {Float} additional_bytes The padding size
	 */
	public function prep(size: Float, additional_bytes: Float):Void;

	/**
	 * @param {Float} byte_size
	 */
	public function pad(byte_size: Float):Void;

	/**
	 * @param {Float} value
	 */
	public function writeInt8(value: Float):Void;

	/**
	 * @param {Float} value
	 */
	public function writeInt16(value: Float):Void;

	/**
	 * @param {Float} value
	 */
	public function writeInt32(value: Float):Void;

	/**
	 * @param {flatbuffers.Long} value
	 */
	public function writeInt64(value: Long):Void;

	/**
	 * @param {Float} value
	 */
	public function writeFloat32(value: Float):Void;

	/**
	 * @param {Float} value
	 */
	public function writeFloat64(value: Float):Void;

	/**
	 * @param {Float} value
	 */
	public function addInt8(value: Float):Void;

	/**
	 * @param {Float} value
	 */
	public function addInt16(value: Float):Void;

	/**
	 * @param {Float} value
	 */
	public function addInt32(value: Float):Void;

	/**
	 * @param {flatbuffers.Long} value
	 */
	public function addInt64(value: Long):Void;

	/**
	 * @param {Float} value
	 */
	public function addFloat32(value: Float):Void;

	/**
	 * @param {Float} value
	 */
	public function addFloat64(value: Float):Void;

	/**
	 * @param {Float} voffset
	 * @param {Float} value
	 * @param {Float} defaultValue
	 */
	public function addFieldInt8(voffset: Float, value: Float, defaultValue: Float):Void;

	/**
	 * @param {Float} voffset
	 * @param {Float} value
	 * @param {Float} defaultValue
	 */
	public function addFieldInt16(voffset: Float, value: Float, defaultValue: Float):Void;

	/**
	 * @param {Float} voffset
	 * @param {Float} value
	 * @param {Float} defaultValue
	 */
	public function addFieldInt32(voffset: Float, value: Float, defaultValue: Float):Void;

	/**
	 * @param {Float} voffset
	 * @param {flatbuffers.Long} value
	 * @param {flatbuffers.Long} defaultValue
	 */
	public function addFieldInt64(voffset: Float, value: Long, defaultValue: Long):Void;

	/**
	 * @param {Float} voffset
	 * @param {Float} value
	 * @param {Float} defaultValue
	 */
	public function addFieldFloat32(voffset: Float, value: Float, defaultValue: Float):Void;

	/**
	 * @param {Float} voffset
	 * @param {Float} value
	 * @param {Float} defaultValue
	 */
	public function addFieldFloat64(voffset: Float, value: Float, defaultValue: Float):Void;

	/**
	 * @param {Float} voffset
	 * @param {flatbuffers.Offset} value
	 * @param {flatbuffers.Offset} defaultValue
	 */
	public function addFieldOffset(voffset: Float, value: Offset, defaultValue: Offset):Void;

	/**
	 * Structs are stored inline, so nothing additional is being added. `d` is always 0.
	 *
	 * @param {Float} voffset
	 * @param {flatbuffers.Offset} value
	 * @param {flatbuffers.Offset} defaultValue
	 */
	public function addFieldStruct(voffset: Float, value: Offset, defaultValue: Offset):Void;

	/**
	 * Structures are always stored inline, they need to be created right
	 * where they're used.  You'll get this assertion failure if you
	 * created it elsewhere.
	 *
	 * @param {flatbuffers.Offset} obj The offset of the created object
	 */
	public function nested(obj: Offset):Void;

	/**
	 * Should not be creating any other object, string or vector
	 * while an object is being constructed
	 */
	public function notNested():Void;

	/**
	 * Set the current vtable at `voffset` to the current location in the buffer.
	 *
	 * @param {Float} voffset
	 */
	public function slot(voffset: Float):Void;

	/**
	 * @returns {flatbuffers.Offset} Offset relative to the end of the buffer.
	 */
	public function offset(): Offset;

	/**
	 * Doubles the size of the backing ByteBuffer and copies the old data towards
	 * the end of the new buffer (since we build the buffer backwards).
	 *
	 * @param {flatbuffers.ByteBuffer} bb The current buffer with the existing data
	 * @returns {flatbuffers.ByteBuffer} A new byte buffer with the old data copied
	 * to it. The data is located at the end of the buffer.
	 */
	public static function growByteBuffer(bb: ByteBuffer): ByteBuffer;

	/**
	 * Adds on offset, relative to where it will be written.
	 *
	 * @param {flatbuffers.Offset} offset The offset to add
	 */
	public function addOffset(offset: Offset):Void;

	/**
	 * Start encoding a new object in the buffer.  Users will not usually need to
	 * call this directly. The FlatBuffers compiler will generate helper methods
	 * that call this method internally.
	 *
	 * @param {Float} numfields
	 */
	public function startObject(numfields: Float):Void;

	/**
	 * Finish off writing the object that is under construction.
	 *
	 * @returns {flatbuffers.Offset} The offset to the object inside `dataBuffer`
	 */
	public function endObject(): Offset;

	/**
	 * @param {flatbuffers.Offset} root_table
	 * @param {string=} file_identifier
	 */
	public function finish(root_table: Offset, file_identifier?: string):Void;

	/**
	 * This checks a required field has been set in a given table that has
	 * just been constructed.
	 *
	 * @param {flatbuffers.Offset} table
	 * @param {Float} field
	 */
	public function requiredField(table: Offset, field: Float):Void;

	/**
	 * Start a new array/vector of objects.  Users usually will not call
	 * this directly. The FlatBuffers compiler will create a start/end
	 * method for vector types in generated code.
	 *
	 * @param {Float} elem_size The size of each element in the array
	 * @param {Float} num_elems The Float of elements in the array
	 * @param {Float} alignment The alignment of the array
	 */
	public function startVector(elem_size: Float, num_elems: Float, alignment: Float):Void;

	/**
	 * Finish off the creation of an array and all its elements. The array must be
	 * created with `startVector`.
	 *
	 * @returns {flatbuffers.Offset} The offset at which the newly created array
	 * starts.
	 */
	public function endVector(): Offset;

	/**
	 * Encode the string `s` in the buffer using UTF-8. If a Uint8Array is passed
	 * instead of a string, it is assumed to contain valid UTF-8 encoded data.
	 *
	 * @param {string|Uint8Array} s The string to encode
	 * @return {flatbuffers.Offset} The offset in the buffer where the encoded string starts
	 */
	public function createString(s: string|Uint8Array): Offset;

	/**
	 * Conveniance function for creating Long objects.
	 *
	 * @param {Float} low
	 * @param {Float} high
	 * @returns {Long}
	 */
	public function createLong(low: Float, high: Float): Long;
}

////////////////////////////////////////////////////////////////////////////////

@:jsRequire("flatbuffers", "ByteBuffer")
extern class ByteBuffer {
	/**
	 * @public static varructor
	 * @param {Uint8Array} bytes
	 */
	public function new(bytes:js.html.Uint8Array);
	
	/**
	 * @param {Float} byte_size
	 * @returns {flatbuffers.ByteBuffer}
	 */
	public static function allocate(byte_size:Float):ByteBuffer;

	/**
	 * @returns {Uint8Array}
	 */
	public function bytes():js.html.Uint8Array;

	/**
	 * @returns {Float}
	 */
	public function position():Float;

	/**
	 * @param {Float} position
	 */
	public function setPosition(position:Float):Void;

	/**
	 * @returns {Float}
	 */
	public function capacity():Float;

	/**
	 * @param {Float} offset
	 * @returns {Float}
	 */
	public function readInt8(offset:Float):Float;

	/**
	 * @param {Float} offset
	 * @returns {Float}
	 */
	public function readUint8(offset:Float):Float;

	/**
	 * @param {Float} offset
	 * @returns {Float}
	 */
	public function readInt16(offset:Float):Float;

	/**
	 * @param {Float} offset
	 * @returns {Float}
	 */
	public function readUint16(offset:Float):Float;

	/**
	 * @param {Float} offset
	 * @returns {Float}
	 */
	public function readInt32(offset:Float):Float;

	/**
	 * @param {Float} offset
	 * @returns {Float}
	 */
	public function readUint32(offset:Float):Float;

	/**
	 * @param {Float} offset
	 * @returns {flatbuffers.Long}
	 */
	public function readInt64(offset:Float):Long;

	/**
	 * @param {Float} offset
	 * @returns {flatbuffers.Long}
	 */
	public function readUint64(offset:Float):Long;

	/**
	 * @param {Float} offset
	 * @returns {Float}
	 */
	public function readFloat32(offset:Float):Float;

	/**
	 * @param {Float} offset
	 * @returns {Float}
	 */
	public function readFloat64(offset:Float):Float;

	/**
	 * @param {Float} offset
	 * @param {Float} value
	 */
	public function writeInt8(offset:Float, value:Float):Void;

	/**
	 * @param {Float} offset
	 * @param {Float} value
	 */
	public function writeUint8(offset:Float, value:Float):Void;

	/**
	 * @param {Float} offset
	 * @param {Float} value
	 */
	public function writeInt16(offset:Float, value:Float):Void;

	/**
	 * @param {Float} offset
	 * @param {Float} value
	 */
	public function writeUint16(offset:Float, value:Float):Void;

	/**
	 * @param {Float} offset
	 * @param {Float} value
	 */
	public function writeInt32(offset:Float, value:Float):Void;

	/**
	 * @param {Float} offset
	 * @param {Float} value
	 */
	public function writeUint32(offset:Float, value:Float):Void;

	/**
	 * @param {Float} offset
	 * @param {flatbuffers.Long} value
	 */
	public function writeInt64(offset:Float, value:Long):Void;

	/**
	 * @param {Float} offset
	 * @param {flatbuffers.Long} value
	 */
	public function writeUint64(offset:Float, value:Long):Void;

	/**
	 * @param {Float} offset
	 * @param {Float} value
	 */
	public function writeFloat32(offset:Float, value:Float):Void;

	/**
	 * @param {Float} offset
	 * @param {Float} value
	 */
	public function writeFloat64(offset:Float, value:Float):Void;

	/**
	 * Look up a field in the vtable, return an offset into the object, or 0 if the
	 * field is not present.
	 *
	 * @param {Float} bb_pos
	 * @param {Float} vtable_offset
	 * @returns {Float}
	 */
	public function __offset(bb_pos:Float, vtable_offset:Float):Float;

	/**
	 * Initialize any Table-derived type to point to the union at the given offset.
	 *
	 * @param {flatbuffers.Table} t
	 * @param {Float} offset
	 * @returns {flatbuffers.Table}
	 */
	public function __union<T:Table>(t: T, offset:Float): T;

	/**
	 * Create a JavaScript string from UTF-8 data stored inside the FlatBuffer.
	 * This allocates a new string and converts to wide chars upon each access.
	 *
	 * To avoid the conversion to UTF-16, pass flatbuffers.Encoding.UTF8_BYTES as
	 * the "optionalEncoding" argument. This is useful for avoiding conversion to
	 * and from UTF-16 when the data will just be packaged back up in another
	 * FlatBuffer later on.
	 *
	 * @param {Float} offset
	 * @param {flatbuffers.Encoding=} optionalEncoding Defaults to UTF16_STRING
	 * @returns {string|Uint8Array}
	 */
	public function __string(offset:Float, ?optionalEncoding: Encoding):haxe.extern.EitherType<String, js.html.Uint8Array>;

	/**
	 * Retrieve the relative offset stored at "offset"
	 * @param {Float} offset
	 * @returns {Float}
	 */
	public function __indirect(offset:Float):Float;

	/**
	 * Get the start of data of a vector whose offset is stored at "offset" in this object.
	 *
	 * @param {Float} offset
	 * @returns {Float}
	 */
	public function __vector(offset:Float):Float;

	/**
	 * Get the length of a vector whose offset is stored at "offset" in this object.
	 *
	 * @param {Float} offset
	 * @returns {Float}
	 */
	public function __vector_len(offset:Float):Float;

	/**
	 * @param {string} ident
	 * @returns {boolean}
	 */
	public function __has_identifier(ident:String):Bool;

	/**
	 * Conveniance function for creating Long objects.
	 *
	 * @param {Float} low
	 * @param {Float} high
	 * @returns {Long}
	 */
	public function createLong(low:Float, high:Float):Long;
}
