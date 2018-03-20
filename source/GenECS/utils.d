module GenECS.utils;

import std.traits;

import GenECS.__generated__.includes;

struct Component
{
    int count = -1;
}
struct System{}
struct Internal{}

struct In(alias Variable)
{
    enum variable = fullyQualifiedName!(Variable);
    string parameter;
    int dependencyGroup = 0;
}

struct Out(alias Variable)
{
    enum variable = fullyQualifiedName!(Variable);
    string parameter;
    int dependencyGroup = 0;
}

struct InAll(alias Variable)
{
    alias variable = Variable;
    string parameter;
}

struct OutAll(alias Variable)
{
    alias variable = Variable;
    string parameter;
}

struct Requires(alias component)
{
}

template SOA(Struct) 
{
    struct SOA  
    {
        enum MEMBERNAME(size_t N) = __traits(identifier, Struct.tupleof[N]);

        static __gentypes() 
        {
            string ret;
            foreach (I, TYPE; typeof(Struct.tupleof))
                ret ~= "typeof(Struct.tupleof["~I.stringof~"])[] "~MEMBERNAME!I~";";
            return ret;
        }
        mixin(__gentypes());

        public this(size_t capacity)
        {
            foreach (I, TYPE; typeof(Struct.tupleof))
                mixin(MEMBERNAME!I ~ " = new "~TYPE.stringof~"[capacity];");
        }

        public void Copy(size_t src, size_t dst)
        {
            foreach (I, TYPE; typeof(Struct.tupleof))
            {
                mixin(MEMBERNAME!I ~ "[dst] = " ~ MEMBERNAME!I ~ "[src];");
            }
        }
    }
}

import std.string;
void SplitFQN(string fqn, out string namespace, out string name) pure
{
    int index = cast(int)fqn.lastIndexOf('.');
    namespace = fqn[0 .. index];
    name = fqn[index+1 .. fqn.length];
}

string GetSOANameFromComponent(string component) pure
{
    string SOAName = component[0..1].toLower() ~ component[1..component.length] ~ "s";
    return SOAName;
}