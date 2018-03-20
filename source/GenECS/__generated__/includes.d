module GenECS.__generated__.includes;

public import GenECS.systems.transform;
public import GenECS.components.transform;
enum SystemModules = [
"GenECS.systems.transform"
];

enum ComponentModules = [
"GenECS.components.transform"
];



import std.array;
import std.traits;
import std.conv;
import std.algorithm;
import std.uni;

// New Generator

struct GeneratorSystemInput
{
    string moduleName;
    string componentName;
    string variableName;
    string fullyQualifiedName;
    int componentID = -1;
    string parameter;
    int dependencyGroup = 0;
}

struct GeneratorSystemOutput
{
    string moduleName;
    string componentName;
    string variableName;
    string fullyQualifiedName;
    int componentID = -1;
    string parameter;
    int dependencyGroup = 0;
}

struct GeneratorSystem
{
    string name;
    string moduleName;
    string fullyQualifiedName;
    ulong[] dependencyKeys;
    GeneratorSystemInput[] inputs;
    GeneratorSystemOutput[] outputs;
    string[] parameters;
}

struct GeneratorComponent
{
    string name;
    string moduleName;
    string fullyQualifiedName;
    uint count;
    ulong id;
}

struct GeneratorContext
{
    GeneratorSystem[] systems;
    GeneratorComponent[] components;
    string debugString;
}

enum ECSReservedKeywords = 
[
    "Update"
];

void _GenScanSystem(alias System)(ref GeneratorContext context) pure
{
    alias systemFQN = fullyQualifiedName!(System);

    pragma(msg, "ECS Compiletime Found system: " ~ systemFQN);
    GeneratorSystem newSystem;

    {
        string moduleName;
        string systemName;
        SplitFQN(systemFQN, moduleName, systemName);

        newSystem.name = systemName;
        newSystem.moduleName = moduleName;
        newSystem.fullyQualifiedName = systemFQN;
    }

    foreach(keyword; ECSReservedKeywords)
    {
        assert(newSystem.name != keyword, "ECS Compiletime: " ~ newSystem.fullyQualifiedName  ~ " '" ~ keyword ~ "' is a reserved keyword and thus not an allowed name for a system");
    }

    alias inputs = getUDAs!(System, In);
    foreach(input; inputs)
    {
        GeneratorSystemInput newInput;

        string component;
        string variableName;
        SplitFQN(input.variable, component, variableName);

        string moduleName;
        string componentName;
        SplitFQN(component, moduleName, componentName);

        newInput.moduleName = moduleName;
        newInput.componentName = componentName;
        newInput.variableName = variableName;
        newInput.fullyQualifiedName = input.variable;
        newInput.parameter = input.parameter;
        newInput.dependencyGroup = input.dependencyGroup;

        newSystem.inputs ~= newInput;
    }

    alias outputs = getUDAs!(System, Out);
    foreach(output; outputs)
    {
        GeneratorSystemOutput newOutput;

        string component;
        string variableName;
        SplitFQN(output.variable, component, variableName);

        string moduleName;
        string componentName;
        SplitFQN(component, moduleName, componentName);

        newOutput.moduleName = moduleName;
        newOutput.componentName = componentName;
        newOutput.variableName = variableName;
        newOutput.fullyQualifiedName = output.variable;
        newOutput.parameter = output.parameter;
        newOutput.dependencyGroup = output.dependencyGroup;

        newSystem.outputs ~= newOutput;
    }

    foreach(parameter; ParameterIdentifierTuple!(System))
    {
        newSystem.parameters ~= parameter;
    }

    context.systems ~= newSystem;
}

void _GenScanComponent(alias Comp)(ref GeneratorContext context) pure
{
    alias componentFQN = fullyQualifiedName!(Comp);

    pragma(msg, "ECS Compiletime Found component: " ~ componentFQN);

    string moduleName;
    string componentName;
    SplitFQN(componentFQN, moduleName, componentName);

    GeneratorComponent newComponent;
    newComponent.name = componentName;
    newComponent.moduleName = moduleName;
    newComponent.fullyQualifiedName = componentFQN;

    alias components = getUDAs!(Comp, Component);
    foreach (component; components) // Find the Component UDA
    {
        newComponent.count = component.count;
        break;
    }

    context.components ~= newComponent;
}

void _GenScanModule(string M, int scanType)(ref GeneratorContext context) pure
{   
    mixin("static import Module = " ~ M ~ ";");

    if (scanType == SCANTYPE_System)
    {
        // Scan for systems
        alias systems = getSymbolsByUDA!(Module, System);
        foreach(system; systems)
        {
            alias systemFQN = fullyQualifiedName!(system);

            bool alreadyExists = false;
            foreach(GeneratorSystem genSystem; context.systems)
            {
                if (genSystem.name == systemFQN)
                {
                    alreadyExists = true;
                    break;
                }
            }

            if (alreadyExists)
                continue;

            _GenScanSystem!(system)(context);
            
        }
    }
    else if (scanType == SCANTYPE_Component)
    {
        // Scan for components
        alias components = getSymbolsByUDA!(Module, Component);
        foreach(component; components)
        {
            alias componentFQN = fullyQualifiedName!(component);

            bool alreadyExists = false;
            foreach(GeneratorComponent genComponent; context.components)
            {
                if (genComponent.name == componentFQN)
                {
                    alreadyExists = true;
                    break;
                }
            }

            if (alreadyExists)
                continue;

            _GenScanComponent!(component)(context);
        }
    }
    else
    {
        assert(false, "ECS Compiletime: ERROR - Unknown scan type");
    }
    
}

string GenScanModule(string[] SMS, int scanType)() pure {
	string ret;
	
	foreach(sm; SMS) {
		ret ~= "     _GenScanModule!(\"" ~ sm ~ "\", " ~ to!string(scanType) ~ ")(context);\n";
	}
	
	return ret;
}

string GenResolveSystemDependencies(ref GeneratorContext context) pure
{

    string dbg = "\"Systems: " ~ to!string(context.systems.length) ~ " Components: " ~ to!string(context.components.length) ~ "\"";
    return dbg;
}

enum SCANTYPE_System = 0;
enum SCANTYPE_Component = 1;

string ResolveSystemKeys(ref GeneratorContext context) pure
{
    auto dbg = appender!string;
    foreach (ref system; context.systems)
    {
        ulong[] dependencyKeys;
        foreach(ref input; system.inputs)
        {
            int count = 0;

            foreach(component; context.components)
            {
                if (input.componentName == component.name)
                {
                    input.componentID = count;

                    while (dependencyKeys.length <= input.dependencyGroup)
                        dependencyKeys ~= 0;

                    dependencyKeys[input.dependencyGroup] = dependencyKeys[input.dependencyGroup] | (1 << count);
                    break;
                }
                count++;
            }
        }

        foreach(ref output; system.outputs)
        {
            int count = 0;

            foreach(component; context.components)
            {
                if (output.componentName == component.name)
                {
                    output.componentID = count;
                    
                    while (dependencyKeys.length <= output.dependencyGroup)
                        dependencyKeys ~= 0;

                    dependencyKeys[output.dependencyGroup] = dependencyKeys[output.dependencyGroup] | (1 << count);
                    break;
                }
                count++;
            }
        }

        system.dependencyKeys = dependencyKeys;
    }
    return dbg.data;
}

GeneratorContext BuildGeneratorContext() pure
{
    GeneratorContext context;
    mixin(GenScanModule!(SystemModules, SCANTYPE_System)());
    mixin(GenScanModule!(ComponentModules, SCANTYPE_Component)());
    context.debugString = ResolveSystemKeys(context);
    return context;
}

string GenComponentStores()
{
    GeneratorContext context = BuildGeneratorContext();

    auto func = appender!string;
    
    int counter = 0;
    foreach(GeneratorComponent component; context.components)
    {
        string componentNameID = component.name ~ "ID";
        // enum transformComponentID = (1 << 0)
        func.put("enum " ~ componentNameID ~ " = (1 << " ~ to!string(counter) ~ ");\n");
        // ComponentStore!(TransformComponent, transformComponentID) transformComponents;
        func.put("ComponentStore!(" ~ component.name ~ ", " ~ componentNameID ~ ") " ~ GetSOANameFromComponent(component.name) ~ ";\n");

        counter++;
    }
    
    return func.data;
}

string GenInit()
{
    GeneratorContext context = BuildGeneratorContext();

    auto func = appender!string;

    func.put("try\n{\n");
    foreach (component; context.components)
    {
        // transformComponents = new typeof(transformComponents)(64);
        func.put(GetSOANameFromComponent(component.name) ~ " = new typeof(" ~ GetSOANameFromComponent(component.name) ~ ")(" ~ to!string(component.count) ~ ");\n");
    }
    func.put("} \ncatch(Throwable e) \n{\n");
    func.put("import core.sys.windows.windows;\n");
    func.put("MessageBoxA(null, e.msg.toStringz(), null, MB_ICONERROR);\n");
    func.put("}\n");
    return func.data;
}

string GenUpdate()
{
    GeneratorContext context = BuildGeneratorContext();

    auto func = appender!string;

    foreach(system; context.systems)
    {
        string[] variables;
        string[] parameters;

        func.put("//" ~ system.fullyQualifiedName ~ "\n");

        foreach(output; system.outputs)
        {
            string componentName = context.components[output.componentID].name;
            string SOAName = GetSOANameFromComponent(componentName);
            func.put("auto out_" ~ output.variableName ~ " = " ~ SOAName ~ ".Write!(" ~ to!string(system.dependencyKeys[output.dependencyGroup]) ~ ", typeof(" ~ output.fullyQualifiedName ~ "), \"" ~ output.variableName ~ "\");\n"); // Declare them
        
            variables ~= "out_" ~ output.variableName;
            parameters ~= output.parameter;
        }

        foreach(input; system.inputs)
        {
            string componentName = context.components[input.componentID].name;
            string SOAName = GetSOANameFromComponent(componentName);

            variables ~= SOAName ~ ".Read!(" ~ to!string(system.dependencyKeys[input.dependencyGroup]) ~ ", typeof(" ~ input.fullyQualifiedName ~ "), \"" ~ input.variableName ~ "\")";
            parameters ~= input.parameter;
        }

        func.put(system.name ~ "(");
        
        bool first = true;
        foreach (parameter; system.parameters) // Find the parameter name and match them with the registered ins/outs
        {
            bool found = false;
            for(int i = 0; i < parameters.length; i++)
            {
                if (parameter == parameters[i])
                {
                    if (!first)
                        func.put(",\n");
                    func.put(variables[i]);
                    found = true;
                    break;
                }
            }
            
            assert(found, "Error: ECS System " ~ system.fullyQualifiedName ~ " has an unbound parameter '" ~ parameter ~ "', this is not allowed");
            first = false;
        }

        func.put(");\n");

        foreach(output; system.outputs)
        {
            string componentName = context.components[output.componentID].name;
            string SOAName = GetSOANameFromComponent(componentName);

            func.put(SOAName ~ ".Feedback!(" ~ to!string(system.dependencyKeys[output.dependencyGroup]) ~ ", \"" ~ output.variableName ~ "\")(" ~ "out_" ~ output.variableName ~ ");\n"); // Declare them
        }
        func.put("\n");
    }

    return func.data;
}

string GenRegisterEntity() pure
{
    GeneratorContext context = BuildGeneratorContext();

    auto func = appender!string;    
    foreach(component; context.components)
    {
        func.put(GetSOANameFromComponent(component.name) ~ ".Add(type);\n");
    }

    return func.data;
}

string GenVerify() pure
{
    GeneratorContext context = BuildGeneratorContext();

    auto func = appender!string;    
    foreach(component; context.components)
    {
        func.put(GetSOANameFromComponent(component.name) ~ ".Verify();\n");
    }

    return func.data;
}
