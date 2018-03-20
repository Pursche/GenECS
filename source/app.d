import std.stdio;

import GenECS.systemshandler;

void main()
{
	GenECS.systemshandler.Init();

	for(int i = 0; i < 10; i++)
	{
		GenECS.systemshandler.Update(0.1);
	}
	writeln("ECS has been created and run 10 times");
}
