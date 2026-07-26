// Dayne
// Input
// February 2024

Button :: struct {
    just_pressed : bool;
    is_held : bool;
}

press :: (button: *Button) {
    button.just_pressed = true;
    button.is_held = true;
}

release :: (button: *Button) {
    button.just_pressed = false;
    button.is_held = false;
}

update :: (button: *Button) {
    if button.just_pressed {
        button.just_pressed = false;
        button.is_held = true;
    }
}

post_frame_update :: (input: *Input) {
    update(*input.up);
    update(*input.left);
    update(*input.down);
    update(*input.right);
    update(*input.north);
    update(*input.south);
    update(*input.east);
    update(*input.west);
    update(*input.start);
    update(*input.select);

    update(*input.left_mouse);
    update(*input.right_mouse);
    update(*input.middle_mouse);
}


Input :: struct {
    up      : Button;
    left    : Button;
    down    : Button;
    right   : Button;

    north   : Button;
    south   : Button;
    east    : Button;
    west    : Button;

    start   : Button;
    select  : Button;

    mouse_active : bool = true;
    mouse_position : Pair;
    left_mouse  : Button;
    right_mouse : Button;
    middle_mouse: Button;
}


gather_input :: (input: *Input, gamepad: *SDL_Joystick) {
    event : SDL_Event;
    while SDL_PollEvent(*event) {
        ImGui_ImplSdl_ProcessEvent(*event);
        if event.type == {
            case SDL_QUIT;
                program_state.running = false;

            case SDL_KEYUP;
                if program_state.imgui_capturing_keyboard return;

                {
                    if event.key.keysym.sym == SDLK_w       release(*input.up);
                    if event.key.keysym.sym == SDLK_a       release(*input.left);
                    if event.key.keysym.sym == SDLK_s       release(*input.down);
                    if event.key.keysym.sym == SDLK_d       release(*input.right);

                    if event.key.keysym.sym == SDLK_h       release(*input.south);
                    if event.key.keysym.sym == SDLK_j       release(*input.east);
                    if event.key.keysym.sym == SDLK_k       release(*input.west);
                    if event.key.keysym.sym == SDLK_l       release(*input.north);

                    if event.key.keysym.sym == SDLK_ESCAPE  release(*input.start);
                    if event.key.keysym.sym == SDLK_RETURN  release(*input.select);
                }

            case SDL_KEYDOWN;
                if program_state.imgui_capturing_keyboard return;

                // Main Program Inputs
                {
                    if event.key.repeat != 0 return;

                    if event.key.keysym.sym == SDLK_w       press(*input.up);
                    if event.key.keysym.sym == SDLK_a       press(*input.left);
                    if event.key.keysym.sym == SDLK_s       press(*input.down);
                    if event.key.keysym.sym == SDLK_d       press(*input.right);

                    if event.key.keysym.sym == SDLK_h       press(*input.south);
                    if event.key.keysym.sym == SDLK_j       press(*input.east);
                    if event.key.keysym.sym == SDLK_k       press(*input.west);
                    if event.key.keysym.sym == SDLK_l       press(*input.north);

                    if event.key.keysym.sym == SDLK_ESCAPE  press(*input.start);
                    if event.key.keysym.sym == SDLK_RETURN  press(*input.select);
                }

                // Development keybinds
                {
                    if event.key.keysym.sym == SDLK_r {
                        if program_state.current_scene == {
                            case .GAME;
                            switch_scene(.EDITOR);
                            activate_mouse();

                            case .EDITOR;
                            switch_scene(.GAME);
                            deactivate_mouse();
                        }
                    }

                    if event.key.keysym.sym == SDLK_F1 {
                        program_state.mode = .NORMAL;
                    }

                    if event.key.keysym.sym == SDLK_F2 {
                        program_state.mode = .DEBUG;
                    }

                    if event.key.keysym.sym == SDLK_1 {
                        program_state.simulation_state.paused = !program_state.simulation_state.paused;
                    }

                    if event.key.keysym.sym == SDLK_2 {
                        program_state.simulation_state.step = true;
                    }
                }

            case SDL_MOUSEBUTTONDOWN;
                if program_state.imgui_capturing_mouse return;

                // Main Program Inputs
                {
                    if event.button.button == SDL_BUTTON_LEFT   press(*input.left_mouse);
                    if event.button.button == SDL_BUTTON_RIGHT  press(*input.right_mouse);
                    if event.button.button == SDL_BUTTON_MIDDLE press(*input.middle_mouse);
                }

            case SDL_MOUSEBUTTONUP;
                if program_state.imgui_capturing_mouse return;

                // Main Program Inputs
                {
                    if event.button.button == SDL_BUTTON_LEFT   release(*input.left_mouse);
                    if event.button.button == SDL_BUTTON_RIGHT  release(*input.right_mouse);
                    if event.button.button == SDL_BUTTON_MIDDLE release(*input.middle_mouse);
                }



            case SDL_MOUSEMOTION;
                if program_state.imgui_capturing_mouse return;

                // Main Program Inputs
                {
                    // @TODO: Review these arbitrary offsets for actual pixel correctness.
                    input.mouse_position.x = cast(int)(event.motion.x * 
                        (cast(float)PIXEL_WIDTH  / graphics_context.window_width)) + 1
                    ;
                    input.mouse_position.y = PIXEL_HEIGHT - cast(int)(event.motion.y * 
                        (cast(float)PIXEL_HEIGHT / graphics_context.window_height)) - 1
                    ;
                }


            JOYSTICK_DEAD_ZONE :: 8000;
            case SDL_JOYBUTTONDOWN;
                // 0, 1, 2, 3 : face buttons
                // 4, 5 : left bumper / right bumper
                // 6, 7 : select / start
                // 8, 9 : pressing in left stick / right stick

                if event.jbutton.button == 0 then press(*input.south);
                if event.jbutton.button == 1 then press(*input.east); 
                if event.jbutton.button == 2 then press(*input.west);
                if event.jbutton.button == 3 then press(*input.north);
                if event.jbutton.button == 6 then press(*input.start);
                if event.jbutton.button == 7 then press(*input.select);

            case SDL_JOYBUTTONUP;
                if event.jbutton.button == 0 then release(*input.south);
                if event.jbutton.button == 1 then release(*input.east); 
                if event.jbutton.button == 2 then release(*input.west);
                if event.jbutton.button == 3 then release(*input.north);
                if event.jbutton.button == 6 then release(*input.start);
                if event.jbutton.button == 7 then release(*input.select);

            case SDL_JOYHATMOTION;
                hat_state : u8;
                hat_state = event.jhat.value;

                if hat_state & 1 then press(*input.up);     else release(*input.up);   
                if hat_state & 2 then press(*input.right);  else release(*input.right);
                if hat_state & 4 then press(*input.down);   else release(*input.down); 
                if hat_state & 8 then press(*input.left);   else release(*input.left); 

            case SDL_JOYDEVICEADDED;
                gamepad = SDL_JoystickOpen(0);
                assert(gamepad != null);

            case SDL_JOYDEVICEREMOVED;
                log("Gamepad removed! ... Just figured you'd like to know <:");
                gamepad = null;

            case SDL_WINDOWEVENT;
                if event.window.event == {
                    case .SDL_WINDOWEVENT_SIZE_CHANGED; {
                        graphics_context.window_width  = event.window.data1;
                        graphics_context.window_height = event.window.data2;

                        #if GAME_ASPECT_RATIO > SCREEN_ASPECT_RATIO {
                            graphics_context.viewport_width = graphics_context.window_width;
                            graphics_context.viewport_height  = cast(s32)(graphics_context.viewport_width / GAME_ASPECT_RATIO);
                        }
                        else {
                            graphics_context.viewport_height = graphics_context.window_height;
                            graphics_context.viewport_width  = cast(s32)(graphics_context.viewport_height * GAME_ASPECT_RATIO);
                        }
                    }

                    case .SDL_WINDOWEVENT_ENTER; {
                        input.mouse_active = true;
                    }

                    case .SDL_WINDOWEVENT_LEAVE; {
                        input.mouse_active = false;
                    }
                }
        }
    }
}
