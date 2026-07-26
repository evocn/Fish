// Dayne
// Main
// September 2024

main :: () {
    random_seed(xx current_time_monotonic());

    initialize_everything();

    gamepad: SDL_Joystick;

    main_menu := menu_initialize();

    a: Allocator;
    a.proc = flat_pool_allocator_proc;
    a.data = *game.arena;
    initialize(*game,, allocator=a);

    dt, last_frame := 0.0;
    while program_state.running {
        ////////////////////////////////////////////////////////////////////////////////
        // Frame Startup
        {
        }

        ////////////////////////////////////////////////////////////////////////////////
        // Input
        {
            gather_input(*game.player.input, *gamepad);

            defer {
                post_frame_update(*game.player.input);
            }

            // Dispatch Inputs based on program state
            if #complete program_state.current_scene == {
                case .TITLE;
                    if game.player.input.south.just_pressed {
                        switch_scene(.GAME);

                        // @TODO: Switch as the hour goes by too!
                        get_music_for_the_hour :: () -> string {
                            hour := time().hour;
                            if hour < 7 || hour > 18 then return "sleep";
                            else if hour > 12 then return "nagata";
                            else if hour < 12 then return "bach";
                            else return "nagata";
                        }
                        play_music(get_music_for_the_hour());
                    }

                case .MENU;
                    apply_inputs_to_menu(*main_menu, game.player.input);

                case .EDITOR;
                    apply_inputs_to_editor(*editor, game.player.input);

                case .GAME;
                    if game.player.input.start.just_pressed {
                        switch_scene(.MENU);
                    }

                    if #complete game.player.state == {
                        case .DEFAULT;
                            simulate_interactions(*game);
                    }
            }
        }

        ////////////////////////////////////////////////////////////////////////////////
        // Simulate
        {
            if #complete program_state.current_scene == {
                case .TITLE;
                case .MENU;
                case .EDITOR;
                case .GAME;
                    if simulation_state.paused {
                        if simulation_state.step {
                            simulation_state.step = false;
                            simulate(*game, dt);
                        }
                    }
                    else {
                        simulate(*game, dt);
                    }
            }
        }

        ////////////////////////////////////////////////////////////////////////////////
        // Render
        render(
            game,
            main_menu,
        );

        if program_state.current_scene == .EDITOR {
            update_and_draw_editor(*game);
            ImGui_ImplSdl_RenderDrawLists(ImGui.GetDrawData());
        }

        SDL_GL_SwapWindow(window);
        SDL_Delay(1);

        ////////////////////////////////////////////////////////////////////////////////
        // Frame Cleanup
        {
            Sound.update();

            current_time := cast(float32)seconds_since_init();
            dt = current_time - last_frame;
            last_frame = current_time;

            reset_temporary_storage();
        }
    }

    cleanup_for_shutdown(*game, *main_menu);

    #if DEBUG_MEMORY then report_memory_leaks();
}



// Imports /////////////////////////////////////////////////////////////////////
using Basic :: #import "Basic"()(MEMORY_DEBUGGER=DEBUG_MEMORY);
#import "String";
#import "Math";
#import "Sort";
#import "Random";
#import "Flat_Pool";
#import "Hash_Table";
#import "File";
#import "File_Utilities";
#import "System";
#import "Text_File_Handler";
#import "SDL";
#import "GL";
#import "stb_image";
#import "freetype-2.12.1";
ImGui :: #import "ImGui";
using Sound :: #import "Sound_Player";


////////////////////////////////////////////////////////////////////////////////

#load "initialize.jai";
#load "state.jai";
#load "render.jai";

// Core
#load "core/input.jai";
#load "core/menu.jai";
#load "core/player.jai";
#load "core/tweaks.jai";
#load "core/utils.jai";

// Subsystems
#load "game/game.jai";
#load "graphics/graphics.jai";

#load "audio.jai";

#load "editor/editor.jai";


// Asset Paths
////////////////////////////////////////////////////////////////////////////////
sprites_path    :: "assets/art/sprites";
sheets_path     :: "assets/art/sheets";
fonts_path      :: "assets/fonts";
music_path      :: "assets/audio/music";
sfx_path        :: "assets/audio/sfx";
shaders_path    :: "assets/shaders";

data_path       :: "assets/data";

tweaks_path     :: "bin";
