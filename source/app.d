import std.stdio;
import std.file;
import std.path;

import GenECS.systemshandler;
import GenECS.globals;

import derelict.sfml2;

void main()
{
	chdir(dirName(thisExePath()));

	DerelictSFML2System.load();
    DerelictSFML2Window.load();
    DerelictSFML2Graphics.load();

	GenECS.systemshandler.Init();

	sfVideoMode videoMode = { 800, 600, 32 };
	g_window = sfRenderWindow_create(videoMode, "GenECS", sfClose, null);

	sfTexture* texture = sfTexture_createFromFile("sprite.png", null);
    g_sprite = sfSprite_create();
    sfSprite_setTexture(g_sprite, texture, sfTrue);

	// add some entities
	for (size_t i = 0; i < 10; ++i)
	{
		CreateEntity(TransformComponentID | SpriteComponentID);
	}

	while (sfRenderWindow_isOpen(g_window))
	{
		sfEvent event;
		while (sfRenderWindow_pollEvent(g_window, &event))
        {
            if (event.type == sfEvtClosed)
			{
                sfRenderWindow_close(g_window);
			}
        }

		sfRenderWindow_clear(g_window, sfBlack);

		GenECS.systemshandler.Update(0.1);

		sfRenderWindow_display(g_window);
	}

	sfSprite_destroy(g_sprite);
    sfTexture_destroy(texture);
    sfRenderWindow_destroy(g_window);
}
