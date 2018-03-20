module GenECS.systems.sprite;
import GenECS.components.transform;
import GenECS.components.sprite;
import GenECS.utils;
import GenECS.globals;

import derelict.sfml2;

import std.stdio;

@System()
@In!(TransformComponent.position)("positions")
@In!(TransformComponent.rotation)("rotations")
@In!(SpriteComponent.spriteHandle)("spriteHandles")
void DrawSprites(
    const float[2][] positions, 
    const float[] rotations, 
    const uint[] spriteHandles)
{
    const size_t count = positions.length;
    for (size_t i = 0; i < count; ++i)
    {
        sfVector2f pos; 
        pos.x = positions[i][0];
        pos.y = positions[i][1];
        const float rot = rotations[i];

        sfSprite_setPosition(g_sprite, pos);
        sfSprite_setRotation(g_sprite, rot);

        //writeln(i, ": ", pos.x, ", ", pos.y, ", ", rot);

        sfRenderWindow_drawSprite(g_window, g_sprite, null);
    }
}