# Flatbuffers Haxe
A pure haxe implementation and compiler of Google's FlatBuffers in Haxe. 

## How to install

```bash
  haxelib git flatbuffers https://github.com/troyedwardsjr/flatbuffers-haxe.git
```

or

```bash
  haxelib git flatbuffers https://github.com/troyedwardsjr/flatbuffers-haxe.git
```
## How to compile schema to Haxe

```bash
  haxelib run flatbuffers [filename]
```

Current targets: 
-JS
-C++/Neko
-Android(Java) (Untested, but should work)
-AS3 (Untested, but should work)
ect.

Currently working:
- Structs
- Tables
- Enums
- Namespaces
- RootType
- Scalar and Non-Scalar Types

[MIT LICENSE](https://opensource.org/licenses/MIT "MIT LICENSE")