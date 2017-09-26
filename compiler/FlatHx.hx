package;

class FlatHx
{
	static function main()
	{
		var filePath:String = "";
		var outPath:String = "";
		var relativePath:String = "";
		var argIndex:Int = 0;

		var ArgHandler = hxargs.Args.generate([
			@doc("Out path")
			["-o"] => function(arg:String) {
				// action
				outPath = arg;
			},

			@doc("Fbs file path")
			_ => function(arg:String) {
				// Default: IDL file, exampe - myschema.fbs

				// Check if argument is relative path.
				if(argIndex > 0)
					relativePath = arg;
				else
					filePath = arg;

				argIndex++;
			}
		]);

		var args = Sys.args();
		if (args.length == 0) {
			Sys.println(ArgHandler.getDoc());
		}	else {
			ArgHandler.parse(args);
			compile(relativePath + filePath, relativePath + outPath);
		}
	}

	static function compile(filePath:String, outPath:String):Void 
	{
		// Step 1: Parser & Lexer.
		var jsflData:String = sys.io.File.getContent(filePath);
		var parser:fbs.Parser = new fbs.Parser(byte.ByteData.ofString(jsflData), "ParseInstance");
		var converter:fbs.Converter = new fbs.Converter();
		var parsedObject:fbs.Parser.ParsedObject = parser.parse();
		var convertedModule:fbs.Converter.HaxeModule = converter.convert(parsedObject);
		
		// Step 2: Print module.
		var printer:haxe.macro.Printer = new haxe.macro.Printer();
		var outBuf:StringBuf = new StringBuf(); // Effeciently print Haxe declerations.
		for (t in convertedModule.toplevel) {
				outBuf.add(t);
				outBuf.add("\n\n");
		}
		for (t in convertedModule.types) {
				var s:String = printer.printTypeDefinition(t);
				outBuf.add(s);
				outBuf.add("\n\n");
		}
		if (outBuf.length > 0) {
			// Append dash to end of path if there is none.
			if(outPath.length > 0 && outPath.charCodeAt(outPath.length - 1) != 47) {
				outPath += '/';
			}
			sys.FileSystem.createDirectory(outPath);
			sys.io.File.saveContent('${outPath}${convertedModule.className}.hx', outBuf.toString());
			Sys.println('Successfully compiled to ${outPath}');
		}
	}

}	