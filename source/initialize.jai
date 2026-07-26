// Dayne
// Initialize
// February 2024

initialize_everything :: () {
    set_working_directory_to_base_folder :: () {
        executable_path := path_strip_filename(get_path_of_running_executable());
        set_working_directory(tprint("%/../", executable_path));
    }
    set_working_directory_to_base_folder();


    initialize_sdl();
    initialize_gl();
    initialize_imgui();


    initialize_graphics_context();

    initialize_audio_context();


    // Tweaks File
    apply_default_settings();
    tweaks_file_exists := load_tweaks_file_and_apply_results("all");
    if tweaks_file_exists then log("Applied tweaks file settings.\n");
}


// Subsystem Initialization ////////////////////////////////////////////////////
initialize_sdl :: () {
    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK);

    window = SDL_CreateWindow("June's Fish Tank",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, graphics_context.window_width, graphics_context.window_height,
        SDL_WINDOW_OPENGL|SDL_WINDOW_SHOWN);

    if !window {
        print("Could not create window: %\n", to_string(SDL_GetError()));
        assert(false);
    }
    SDL_SetWindowResizable(window, xx false);

    // Settings
    {
        SDL_ShowCursor(0);
        SDL_SetRelativeMouseMode(SDL_FALSE);

        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);
    }
}


initialize_gl :: () {
    gl_context = SDL_GL_CreateContext(window);
    if !gl_context {
        print("Could not create OpenGL context: %\n", to_string(SDL_GetError()));
        assert(false);
    }
    gl_load(*gl, SDL_GL_GetProcAddress);

    // Settings
    {
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }
}


initialize_imgui :: () {
    imgui_context = ImGui.CreateContext();
    ImGui_ImplSdl_Init(window);

    io := ImGui.GetIO();
    io.Fonts.AddFontFromFileTTF(io.Fonts, "assets/fonts/verdanab.ttf", graphics_context.window_height / 20.0, null, io.Fonts.GetGlyphRangesDefault(io.Fonts));

    // Settings
    {
        ImGui.StyleColorsClassic();
        //ImGui.StyleColorsLight();
    }
}


initialize_graphics_context :: () {
    using graphics_context;

    // Shaders
    basic_shader = make_shader("screen.vs", "basic.fs");
    sprite_shader= make_shader("screen.vs", "texture.fs");
    text_shader  = make_shader("text.vs", "text.fs");
    quad_shader  = make_shader("quad.vs", "quad.fs");

    // Primitives
    initialize_quad_rendering_objects(*quad);

    // Buffers
    initialize_framebuffer();

    // Initialize Fonts
    {
        initialize_freetype();

        initialize_font(*main_font,  "bm.ttf", 9);

        //initialize_font(*small_font, "gosub.otf", 6);
        //initialize_font(*small_font, "small_5x3.ttf", 7);
        initialize_font(*small_font, "bit5x3.ttf", 8);
        //initialize_font(*small_font, "pix3l5.ttf", 7);

        FT_Done_FreeType(ft);
    }


    // Initialize Sprites
    {
        sprite_paths := file_list(sprites_path, recursive = true, follow_directory_symlinks = false,, allocator=temp);
        for path : sprite_paths {
            if path_extension(path) != "png" then continue;

            name := basename(path);

            sprite := table_add(*graphics_context.sprites, copy_string(name), load_sprite(path));
            assert(sprite.loaded);
        }
    }

    // Initialize Spritesheets
    {
        // This array is of sprites who we know are not TILE_SIZE_IN_PIXELS x TILE_SIZE_IN_PIXELS.
        size_exceptions : Table(string, Pair);
        {
            table_add(*size_exceptions, "Anchor", .{32, 32});
            table_add(*size_exceptions, "Food",   .{4, 4});
        }

        sheet_paths := file_list(sheets_path, recursive = true, follow_directory_symlinks = false,, allocator=temp);
        for path : sheet_paths {
            if path_extension(path) != "png" then continue;

            name := basename(path);

            width  := TILE_SIZE_IN_PIXELS;
            height := TILE_SIZE_IN_PIXELS;
            dimensions, success := table_find(*size_exceptions, name);
            if success {
                width  = dimensions.x;
                height = dimensions.y;
            }

            sheet := table_add(*graphics_context.sheets, copy_string(name), load_sheet(path, width, height));
            assert(sheet.loaded);
        }

        deinit(*size_exceptions);
    }
}


initialize_audio_context :: () {
    using audio_context;

    devices := get_devices();
    print("devices: %\n", devices);

    success := sound_player_init(.{});
    assert(success);

    // SFX
    {
        sfx_paths := file_list(sfx_path, recursive = true, follow_directory_symlinks = false,, allocator=temp);
        for path : sfx_paths {
            name := basename(path);

            sfx := table_add(*audio_context.sfx, copy_string(name), load_audio_file(path));
            assert(sfx.loaded);
        }
    }

    // Music
    {
        music_paths := file_list(music_path, recursive = true, follow_directory_symlinks = false,, allocator=temp);
        for path : music_paths {
            name := basename(path);

            music := table_add(*audio_context.music, copy_string(name), load_audio_file(path));
            assert(music.loaded);
        }
    }
}

//
// Shutdown ////////////////////////////////////////////////////////////////////
//

// Note that this function doesn't actually need to exist. The OS will always clean our stuff up.
// This is just here so we can clean house and see the real leaks if they happen when we are debugging memory.
cleanup_for_shutdown :: (game: *Game, menu: *Menu) {
    // Game Cleanup
    {
        reset(*game.arena, overwrite_memory=true);
    }

    array_reset(*menu.elements);

    // Audio Cleanup
    {
        using audio_context;
        sound_player_shutdown();
    }

    // Graphics Cleanup
    {
        using graphics_context;

        deinit(*main_font.characters);
        deinit(*small_font.characters);
    }

    array_reset(*menu.elements);
    reset(*scratch_memory, overwrite_memory=true);

    ImGui_ImplSdl_Shutdown();
    ImGui.DestroyContext(imgui_context);
    SDL_GL_DeleteContext(gl_context);
    SDL_DestroyWindow(window);
    SDL_Quit();
}
