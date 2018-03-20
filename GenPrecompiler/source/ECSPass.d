module ecspass;

import std.file;
import std.stdio;
import std.string;
import std.array;
import std.path;

// TODO: Scan for Systems/Components folder and __generated__ folder

string PathUp(string path)
{
    return path[0 .. lastIndexOf(path, dirSeparator)];
}

string GetModule(string path)
{
    size_t start = indexOf(path, buildPath("GenECS", "systems"));
    if (start == -1)
        start = indexOf(path, buildPath("GenECS", "components"));
    size_t end = lastIndexOf(path, ".d");

    return path[start .. end].replace(dirSeparator, ".");
}

string GetImport(string mod)
{
    return "public import " ~ mod ~ ";"; 
}

void Run()
{
    writeln("Precompiler: Pregenerating ECS code");
    string exePath = thisExePath();
    string[] systems;
    string[] components;
    string[] imports;

    string systemsPath = exePath.PathUp().PathUp() ~ dirSeparator ~ buildPath("source", "GenECS", "systems");
    foreach (string name; dirEntries(systemsPath, SpanMode.depth))
    {
        imports ~= name.GetModule().GetImport();
        systems ~= name.GetModule();
    }
    string componentsPath = exePath.PathUp().PathUp() ~ dirSeparator ~ buildPath("source", "GenECS", "components");
    foreach (string name; dirEntries(componentsPath, SpanMode.depth))
    {
        imports ~= name.GetModule().GetImport();
        components ~= name.GetModule();
    }
    
    string includeDir = exePath.PathUp().PathUp() ~ dirSeparator ~ buildPath("source", "GenECS", "__generated__");
    if (!exists(includeDir))
    {
        mkdir(includeDir);
    }
    string includePath = buildPath(includeDir, "includes.d");
    File includeFile = File(includePath, "w");
    includeFile.writeln("module GenECS.__generated__.includes;\n");
    foreach(string imp; imports)
    {
        includeFile.writeln(imp);
    }

    includeFile.writeln("enum SystemModules = [");
    int count = 0;
    foreach(string system; systems)
    {
        string systemLine = "\"" ~ system ~ "\"";

        if (++count < systems.length)
            systemLine ~= ",";
        includeFile.writeln(systemLine);
    }
    includeFile.writeln("];\n");
    
    includeFile.writeln("enum ComponentModules = [");
    count = 0;
    foreach(string component; components)
    {
        string componentLine = "\"" ~ component ~ "\"";

        if (++count < components.length)
            componentLine ~= ",";
        includeFile.writeln(componentLine);
    }
    includeFile.writeln("];\n");
    

    string[] templateLines;
    string templatePath = exePath.PathUp().PathUp() ~ dirSeparator ~ buildPath("source", "GenECS", "includes.dtemplate");
    File templateFile = File(templatePath, "r");
    auto lines = templateFile.byLine();

    foreach(line; lines)
    {
         includeFile.writeln(line);
    }
}
