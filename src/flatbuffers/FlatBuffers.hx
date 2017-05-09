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
	 * @type {number}
	 * @const
	 */
	public var low:Float;

	/**
	 * @type {number}
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
	 * @param {number} high
	 * @param {number} low
	 */
	public function new(low:Float, high:Float);

	/**
	 * @returns {number}
	 */
	public function toFloat64():Float;

	/**
	 * @param {flatbuffers.Long} other
	 * @returns {boolean}
	 */
	public function equals(other:Long):Bool; // May need to change to Dynamic.

	/**
	 * @param {number} low
	 * @param {number} high
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
	public function new(?initial_size:Float);

	/**
	 * In order to save space, fields that are set to their default value
	 * don't get serialized into the buffer. Forcing defaults provides a
	 * way to manually disable this optimization.
	 *
	 * @param {boolean} forceDefaults true always serializes default values
	 */
	public function forceDefaults(forceDefaults:Bool):Void;

	/**
	 * Get the ByteBuffer representing the FlatBuffer. Only call this after you've
	 * called finish(). The actual data starts at the ByteBuffer's current position,
	 * not necessarily at 0.
	 *
	 * @returns {flatbuffers.ByteBuffer}
	 */
	public function dataBuffer():ByteBuffer;
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
	public function __string(offset:Float, ?optionalEncoding: Encoding):String|Uint8Array;

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
