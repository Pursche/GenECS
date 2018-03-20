module GenECS.systemshandler;
import GenECS.componentstore;
import std.stdio;
import std.string;

// This file relies heavily on compiletime generated code. Here is a quick rundown of the flow
// We start by compiling and running the GenECSPrecompiler project, which will generate includes.d
// (See ECSPass.d for more info how it generates, or includes.d to see the result)
// To generate includes.d, running the precompiler will:
//      1. Scan GenECS/components and GenECS/systems for modules
//      2. Add public imports of all components and systems to the top of the file
//	    3. Create SystemModules and ComponentModules lists
//      4. After pausing to compile and run DryPrecompiler before GenECS, we resume compiling GenECS
//      5. When this file gets compiled, the compiler will find the mixins, run the functions within them and evaluate their returned strings as code
//          * This will run the root generation function (e.g GenUpdate), which in turn runs BuildGeneratorContext which creates a GeneratorContext object in compiletime
//          * GeneratorContext is guaranteed to be identical after every call to BuildGeneratorContext
//	    6. We use the GeneratorContext in different functions (GenUpdate, GenInit, GenComponentStores etc) to generate needed code. Calls to mixin(*function*) actually compiles the code while pragma(msg, *function*) debug prints the result
//      7. Lastly we add some runtime code to the Init function that will output a generatedECS.notd file with all our generated code for easier debugging
//      
// If you want to know what code this generates, start the game and look at generatedECS.notd next to the executable
// If you need to debug this without being able to look at generatedECS.notd, 
// you can uncomment pragma(msg, *function*) calls in this code to see the generated code in the command prompt during compilation
// As a last resort I recommend adding more pragma(msg, *function*) calls in includes.dtemplate for more detailed debugging

import GenECS.utils;

// This file has all our generated includes
import GenECS.__generated__.includes;

//pragma(msg, GenComponentStores());
mixin(GenComponentStores());

import std.array;
import std.traits;
import std.conv;
import std.algorithm;
import std.uni;

export void Init()
{
    //pragma(msg, GenInit());
    mixin(GenInit());
    
    debug(1)
    {
    	File generatedCode = File("generatedECS.notd", "w");
        generatedCode.writeln("// COMPONENTSTORES");
	    generatedCode.writeln(GenComponentStores());
        generatedCode.writeln("// INIT");
	    generatedCode.writeln(GenInit());
        generatedCode.writeln("// REGISTER ENTITY");
        generatedCode.writeln(GenRegisterEntity());
        generatedCode.writeln("// UPDATE");
	    generatedCode.writeln(GenUpdate());
        generatedCode.writeln("// VERIFY");
        generatedCode.writeln(GenVerify());
    }
}

export EntityID CreateEntity(EntityType type)
{
    EntityID id = 0;
    _RegisterEntity(type);
    return 0;//todo
}

void _RegisterEntity(EntityType type)
{
    //pragma(msg, GenRegisterEntity());
    mixin(GenRegisterEntity());
}

void Update(float deltaTime)
{
    //pragma(msg, GenUpdate());
    mixin(GenUpdate());

    //pragma(msg, GenVerify());
    mixin(GenVerify());
}
