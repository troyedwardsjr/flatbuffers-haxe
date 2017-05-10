package;

import flatbuffers.FlatBuffers;
import flatbuffers.FlatBuffers.Builder;
import flatbuffers.FlatBuffers.ByteBuffer;

import util.Webpack;

class Main {
	public static function main() {
		var MyGame = Webpack.require('../fbschemas/myschema_generated.js').MyGame;

		trace(Webpack.require('../fbschemas/myschema_generated.js').MyGame);
		trace(flatbuffers.FlatBuffers);

		var builder = new flatbuffers.Builder(1024);
		var weaponOne = builder.createString('Sword');
		var weaponTwo = builder.createString('Axe');

		// Create the first `Weapon` ('Sword').
		MyGame.Sample.Weapon.startWeapon(builder);
		MyGame.Sample.Weapon.addName(builder, weaponOne);
		MyGame.Sample.Weapon.addDamage(builder, 3);
		var sword = MyGame.Sample.Weapon.endWeapon(builder);
		// Create the second `Weapon` ('Axe').
		MyGame.Sample.Weapon.startWeapon(builder);
		MyGame.Sample.Weapon.addName(builder, weaponTwo);
		MyGame.Sample.Weapon.addDamage(builder, 5);
		var axe = MyGame.Sample.Weapon.endWeapon(builder);

		// Serialize a name for our monster, called 'Orc'.
		var name = builder.createString('Orc');
		// Create a `vector` representing the inventory of the Orc. Each number
		// could correspond to an item that can be claimed after he is slain.
		var treasure = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
		var inv = MyGame.Sample.Monster.createInventoryVector(builder, treasure);
		var weaps = [sword, axe];
		var weapons = MyGame.Sample.Monster.createWeaponsVector(builder, weaps);
		MyGame.Sample.Monster.startMonster(builder);
		MyGame.Sample.Monster.addPos(builder, MyGame.Sample.Vec3.createVec3(builder, 1.0, 2.0, 3.0));
		MyGame.Sample.Monster.addHp(builder, 300);
		MyGame.Sample.Monster.addColor(builder, MyGame.Sample.Color.Red);
		MyGame.Sample.Monster.addName(builder, name);
		MyGame.Sample.Monster.addInventory(builder, inv);
		MyGame.Sample.Monster.addWeapons(builder, weapons);
		MyGame.Sample.Monster.addEquippedType(builder, MyGame.Sample.Equipment.Weapon);
		MyGame.Sample.Monster.addEquipped(builder, axe);
		var orc = MyGame.Sample.Monster.endMonster(builder);
		MyGame.Sample.Monster.addEquippedType(builder, MyGame.Sample.Equipment.Weapon); // Union type
		MyGame.Sample.Monster.addEquipped(builder, axe); // Union data

		// Call `finish()` to instruct the builder that this monster is complete.
		builder.finish(orc); // You could also call `MyGame.Example.Monster.finishMonsterBuffer(builder,
												//          
												// This must be called after `finish()`.
		var bytes = builder.asUint8Array(); // Of type `Uint8Array`.
		
		var buf = new flatbuffers.ByteBuffer(bytes);
		trace(buf);

		var monster = MyGame.Sample.Monster.getRootAsMonster(buf);
		var pos = monster.pos();
		var x = pos.x();
		var y = pos.y();
		var z = pos.z();
		var invLength = monster.inventoryLength();
		var thirdItem = monster.inventory(2);
		var weaponsLength = monster.weaponsLength();
		var secondWeaponName = monster.weapons(1).name();
		var secondWeaponDamage = monster.weapons(1).damage();

		trace(pos);
		trace(x);
		trace(y);
		trace(z);
		trace(invLength);
		trace(thirdItem);
		trace(weaponsLength);
		trace(secondWeaponName);
		trace(secondWeaponDamage);
	}
}