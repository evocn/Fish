// Dayne
// State
// February 2024

using program_state : struct {
    VERSION :: "0.04a";
    DEBUG_MEMORY :: true;

    mode : enum {
        NORMAL;
        DEBUG;
    }

    using external_components : struct {
        window          : *SDL_Window;
        gl_context      : *SDL_GLContext;
        imgui_context   : *ImGui.ImGuiContext;

        imgui_capturing_mouse    := false;
        imgui_capturing_keyboard := false;
    }

    scratch_memory  : Flat_Pool;

    ////////////////////////////////////////////////////////////////////////////

    game    : Game;
    editor  : Editor;
    graphics_context    : Graphics_Context;
    audio_context       : Audio_Context;

    running := true;

    current_scene : Scene = .GAME;
    prior_scene : Scene;

    framerate : float;

    using simulation_state : struct {
        paused : bool;
        step : bool;
    }
}


// Scene Definition
////////////////////////////////////////////////////////////////////////////////

Scene :: enum {
    TITLE;
    MENU;
    EDITOR;
    GAME;
}

switch_scene :: (new_scene: Scene) {
    using program_state;

    prior_scene = current_scene;
    current_scene = new_scene;
}

return_to_prior_scene :: () {
    using program_state;

    current_scene, prior_scene = swap(current_scene, prior_scene);
}
