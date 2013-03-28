stubmaker
=========

Tool to generate Ruby code from modules/classes and methods in memory.

This class can write any Modules/Classes from memory into Ruby code.
It includes constants, class variables, public class methods and public instants
methods. However, methods will not contain any code (they are empty stubs without
return value), but it can satisfy scripts that require these modules/methods.

Usage:

Assuming you want to get stubs for all methods in a module `ModuleName`

```
file = File.expand_path("sketchup.rb")
File.open(file,"w"){|f|
  f.puts( StubMaker.dump(ModuleName) )
}
```
