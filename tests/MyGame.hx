package;

import flatbuffers.FlatBuffers;
import flatbuffers.FlatBuffers.ByteBuffer;
import flatbuffers.FlatBuffers.Offset;
import flatbuffers.FlatBuffers.Builder;
import flatbuffers.FlatBuffers.Long;
import flatbuffers.impl.FlatBuffersPure.Encoding;
import flatbuffers.impl.FlatBuffersPure.TableT;

import haxe.Int32;
import haxe.Int64;
import haxe.io.UInt8Array;
import haxe.io.UInt16Array;
import haxe.io.Int32Array;
#if js
import flatbuffers.io.Float32Array;
import flatbuffers.io.Float64Array;
#else
import haxe.io.Float32Array;
import haxe.io.Float64Array;
#end

import haxe.ds.Either;

enum Color
{
	Red;
	Green;
	Blue;
}

enum Equipment
{
	NONE;
	Weapon;
}

class MyGame 
{
	public function new(){}
}

class Vec3
{
	public var bb:ByteBuffer;
	public var bb_pos:Int;

	public function new() {}

	public function __init(i:Int, bb:ByteBuffer):Vec3
	{
		this.bb_pos = i;
  	this.bb = bb;
  	return this;
	}

	public function x():Float
	{
		return this.bb.readFloat32(this.bb_pos);
	}

	public function y():Float
	{
		return this.bb.readFloat32(this.bb_pos + 4);
	}

	public function z():Float
	{
		return this.bb.readFloat32(this.bb_pos + 8);
	}

	public static function createVec3(builder:Builder, x:Float, y:Float, z:Float):Offset
	{
		builder.prep(4, 12);
		builder.writeFloat32(z);
		builder.writeFloat32(y);
		builder.writeFloat32(x);
		return builder.offset();
	}

}

class Weapon
{
	public var bb:ByteBuffer;
	public var bb_pos:Int;

	public function new() {}

	public function __init(i:Int, bb:ByteBuffer):Weapon
	{
		this.bb_pos = i;
  	this.bb = bb;
  	return this;
	}

	public static function getRootAsWeapon(bb:ByteBuffer, ?obj:Weapon):Weapon
	{
		return obj != null ? obj.__init(bb.readInt32(bb.position()) + bb.position(), bb) : new Weapon().__init(bb.readInt32(bb.position()) + bb.position(), bb);
	}

	public function name(?optionalEncoding:Encoding):String
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 4);
  	return (offset != 0 && offset != null) ? this.bb.__string(this.bb_pos + offset, 0) : null;
	}

	public function damage():Int
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 6);
  	return (offset != 0 && offset != null) ? this.bb.readInt16(this.bb_pos + offset) : 0;
	}

	public static function startWeapon(builder:Builder):Void
	{
		builder.startObject(2);
	}

	public static function addName(builder:Builder, nameOffset:Offset):Void
	{
		builder.addFieldOffset(0, nameOffset, 0);
	}

	public static function addDamage(builder:Builder, damage:Int):Void
	{
		builder.addFieldInt16(1, damage, 0);
	}

	public static function endWeapon(builder:Builder):Offset
	{
		var offset:Null<Int> = builder.endObject();
  	return offset;
	}

}

class Monster
{
	public var bb:ByteBuffer;
	public var bb_pos:Int;

	public function new() {}

	public function __init(i:Int, bb:ByteBuffer):Monster
	{
		this.bb_pos = i;
  	this.bb = bb;
  	return this;
	}

	public static function getRootAsMonster(bb:ByteBuffer, ?obj:Monster):Monster
	{
		return obj != null ? obj.__init(bb.readInt32(bb.position()) + bb.position(), bb) : new Monster().__init(bb.readInt32(bb.position()) + bb.position(), bb);
	}

	public function pos(?obj:Vec3):Vec3
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 4);
		
		return (offset != 0 && offset != null) ? (obj != null ? obj.__init(this.bb_pos + offset, this.bb) : new Vec3().__init(this.bb_pos + offset, this.bb)) : null;
	}

	public function mana():Int
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 6);
  	return (offset != 0 && offset != null) ? this.bb.readInt16(this.bb_pos + offset) : 150;
	}

	public function hp():Int
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 8);
  	return (offset != 0 && offset != null) ? this.bb.readInt16(this.bb_pos + offset) : 100;
	}

	public function name(?optionalEncoding:Encoding):String
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 10);
  	return (offset != 0 && offset != null) ? this.bb.__string(this.bb_pos + offset, 0) : null;
	}


	public function inventory(index:Int):Int
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 14);
  	return (offset != 0 && offset != null) ? this.bb.readUint8(this.bb.__vector(this.bb_pos + offset) + index) : 0;
	}

	public function inventoryLength():Int
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 14);
  	return (offset != 0 && offset != null) ? this.bb.__vector_len(this.bb_pos + offset) : 0;
	}

	public function inventoryArray():UInt8Array
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 14);
		return (offset != 0 && offset != null) ? UInt8Array.fromBytes(this.bb.bytes().view.buffer, Std.int(this.bb.bytes().view.byteOffset + this.bb.__vector(this.bb_pos + offset)), this.bb.__vector_len(this.bb_pos + offset)) : null;
	}

	public function color():Int
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 16);
		return (offset != 0 && offset != null) ? (this.bb.readInt8(this.bb_pos + offset)) : Color.Blue.getIndex();
	}

	public function weapons(index:Int, ?obj:Weapon):Weapon
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 18);
		return (offset != 0 && offset != null) ? (obj != null ? obj.__init(this.bb.__indirect(this.bb.__vector(this.bb_pos + offset) + index * 4), this.bb) : new Weapon().__init(this.bb.__indirect(this.bb.__vector(this.bb_pos + offset) + index * 4), this.bb)) : null;
	}

	public function weaponsLength():Int
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 18);
  	return (offset != 0 && offset != null) ? this.bb.__vector_len(this.bb_pos + offset) : 0;
	}

	public function equippedType():Int
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 20);
		return (offset != 0 && offset != null) ? /** @type {MyGame.Sample.Equipment} */ (this.bb.readUint8(this.bb_pos + offset)) : Equipment.NONE.getIndex();
	}

	public function equipped(obj:TableT):TableT
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 22);
  	return (offset != 0 && offset != null) ? this.bb.__union(obj, this.bb_pos + offset) : null;
	}

	public function path(index:Int, obj:Vec3):Vec3
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 24);
		return (offset != 0 && offset != null) ? (obj != null ? obj.__init(this.bb.__vector(this.bb_pos + offset) + index * 12, this.bb) : new Vec3().__init(this.bb.__vector(this.bb_pos + offset) + index * 12, this.bb)) : null;
	}

	public function pathLength():Int
	{
		var offset:Null<Int> = this.bb.__offset(this.bb_pos, 24);
  	return (offset != 0 && offset != null) ? this.bb.__vector_len(this.bb_pos + offset) : 0;
	}

	public static function startMonster(builder:Builder):Void
	{
		builder.startObject(11);
	}

	public static function addPos(builder:Builder, posOffset:Offset):Void
	{
		builder.addFieldStruct(0, posOffset, 0);
	}

	public static function addMana(builder:Builder, mana:Int):Void
	{
		builder.addFieldInt16(1, mana, 150);
	}

	public static function addHp(builder:Builder, hp:Int):Void
	{
		builder.addFieldInt16(2, hp, 100);
	}

	public static function addName(builder:Builder, nameOffset:Offset):Void
	{
		builder.addFieldOffset(3, nameOffset, 0);
	}

	public static function addInventory(builder:Builder, inventoryOffset:Offset):Void
	{
		builder.addFieldOffset(5, inventoryOffset, 0);
	}

	public static function createInventoryVector(builder:Builder, data:Array<Int>):Offset
	{
		builder.startVector(1, data.length, 1);

		var i = data.length - 1;
		while(i >= 0)
		{
			builder.addInt8(data[i]);
			i--;
		}
		return builder.endVector();
	}

	public static function startInventoryVector(builder:Builder, numElems:Int):Void
	{
		builder.startVector(1, numElems, 1);
	}

	public static function addColor(builder:Builder, color:Color):Void
	{
		builder.addFieldInt8(6, color.getIndex(), Color.Blue.getIndex());
	}

	public static function addWeapons(builder:Builder, weaponsOffset:Offset):Void
	{
		builder.addFieldOffset(7, weaponsOffset, 0);
	}

	public static function createWeaponsVector(builder:Builder, data:Array<Offset>):Offset
	{
		builder.startVector(4, data.length, 4);

		var i = data.length - 1;
		while(i >= 0)
		{
			builder.addOffset(data[i]);
			i--;
		}

		return builder.endVector();
	}

	public static function startWeaponsVector(builder:Builder, numElems:Int):Void
	{
		builder.startVector(4, numElems, 4);
	}

	public static function addEquippedType(builder:Builder, equippedType:Equipment):Void
	{
		builder.addFieldInt8(8, equippedType.getIndex(), Equipment.NONE.getIndex());
	}

	public static function addEquipped(builder:Builder, equippedOffset:Offset):Void
	{
		builder.addFieldOffset(9, equippedOffset, 0);
	}

	public static function addPath(builder:Builder, pathOffset:Offset):Void
	{
		builder.addFieldOffset(10, pathOffset, 0);
	}

	public static function startPathVector(builder:Builder, numElems:Int)
	{
		builder.startVector(12, numElems, 4);
	}
	
	public static function endMonster(builder:Builder):Offset
	{
		var offset:Null<Int> = builder.endObject();
  	return offset;
	}

	public static function finishMonsterBuffer(builder:Builder, offset:Offset):Void
	{
		builder.finish(offset);
	}

}