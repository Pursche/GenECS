module GenECS.systems.transform;
import GenECS.components.transform;
import GenECS.utils;

import std.stdio;

@System()
@In!(TransformComponent.position)("positions")
@In!(TransformComponent.rotation)("rotations")
@In!(TransformComponent.scale)("scales")
@Out!(TransformComponent.matWorld)("worldMatrices")
void UpdateTransform(const float[3][] positions, 
    const float[4][] rotations, 
    const float[3][] scales,
    float[4][] worldMatrices)
{
    writeln("Transform updated");
    for (size_t i = 0; i < positions.length; ++i)
    {
        
        //worldMatrices[i] = Transform(positions[i], rotations[i], scales[i]);
    }
}