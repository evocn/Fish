// Dayne
// Menu
// February 2024

apply_inputs_to_menu :: (menu: *Menu, input: Input) {
    if input.start.just_pressed || input.east.just_pressed {
        return_to_prior_scene();
        play_sfx("click");
    }

    if input.up.just_pressed {
        menu.element_index -= 1;
        if menu.element_index < 0 {
            menu.element_index += 1;
        }
        play_sfx("click");
    }
    if input.down.just_pressed {
        menu.element_index += 1;
        if menu.element_index >= menu.elements.count {
            menu.element_index -= 1;
        }
        play_sfx("click");
    }
    if input.left.just_pressed {
        nudge_menu_element(menu.elements[menu.element_index], left=true);
        play_sfx("click");
    }
    if input.right.just_pressed {
        nudge_menu_element(menu.elements[menu.element_index]);
        play_sfx("click");
    }

    if input.south.just_pressed {
        toggle_menu_element(menu.elements[menu.element_index]);
    }
}

//

menu_initialize :: () -> Menu {
    a: Allocator;
    a.proc = flat_pool_allocator_proc;
    a.data = *scratch_memory;

    new_menu: Menu;

    {
        using new_menu;
        elements.allocator = a;
        name = "Pause";

        resume := New(Menu_Element_Go,, a);
        resume.name = "Resume";
        resume.callback = resume_game;
        array_add(*elements, cast(*Menu_Element)resume);

        screen_mode := New(Menu_Element_Checkbox,, a);
        screen_mode.name = "Fullscreen";
        screen_mode.callback = set_screen_mode_according_to_fullscreen_variable;
        screen_mode.value = *graphics_context.fullscreen;
        array_add(*elements, cast(*Menu_Element)screen_mode);

        sfx := New(Menu_Element_Slider,, a);
        sfx.name = "Sfx";
        sfx.value = *mix_levels[Sound_Category.GENERAL_SFX];
        sfx.callback = null;
        array_add(*elements, cast(*Menu_Element)sfx);

        music := New(Menu_Element_Slider,, a);
        music.name = "Music";
        music.value = *mix_levels[Sound_Category.MUSIC];
        music.callback = null;
        array_add(*elements, cast(*Menu_Element)music);

        quit := New(Menu_Element_Go,, a);
        quit.name = "Quit";
        quit.callback = quit_game;
        array_add(*elements, cast(*Menu_Element)quit);
    }

    return new_menu;
}



Menu :: struct {
    name : string;

    elements : [..] *Menu_Element;
    element_index : int;
}

// Elements below

Menu_Element_Go :: struct {
    using #as menu_element: Menu_Element;
    kind = .GO;

    callback : #type ();
}

Menu_Element_Checkbox :: struct {
    using #as menu_element: Menu_Element;
    kind = .CHECKBOX;

    value : *bool;

    callback : #type ();
}

Menu_Element_Slider :: struct {
    using #as menu_element: Menu_Element;
    kind = .SLIDER;

    value : *float;
    callback : #type ();

    increment : float = 0.25;
    min : float = 0.0;
    max : float = 1.0;
}

Menu_Element :: struct {
    kind : enum #complete {
        GO;
        CHECKBOX;
        SLIDER;
    }

    name : string;
    usual_color: Color = gray;
    hover_color: Color = white;
}


// Functions

toggle_menu_element :: (using element: *Menu_Element) {
    if kind == {
        case .GO;
            using cast(*Menu_Element_Go)element;
            if callback then callback();
            play_sfx("click");

        case .CHECKBOX;
            using cast(*Menu_Element_Checkbox)element;
            value.* = !(value.*);
            if callback then callback();
            play_sfx("click");

        case .SLIDER;
            // Don't do anything.
    }

    save_tweaks_file("all");
}


nudge_menu_element :: (using element: *Menu_Element, left := false) {
    if kind == {
        case .GO; ; // Nothing
        case .CHECKBOX;
            using cast(*Menu_Element_Checkbox)element;
            value.* = !(value.*);
            if callback then callback();
            play_sfx("click");

        case .SLIDER;
            using cast(*Menu_Element_Slider)element;
            if left {
                value.* = clamp(value.* - increment, min, max);
                if callback then callback();
            }
            else {
                value.* = clamp(value.* + increment, min, max);
                if callback then callback();
            }

            play_sfx("click");
    }

    save_tweaks_file("all");
}


// Callbacks for Menu Elements
resume_game :: () {
    return_to_prior_scene();
}

quit_game :: () {
    program_state.running = false;
}

go_to_settings :: () {
    switch_scene(.MENU);
}
