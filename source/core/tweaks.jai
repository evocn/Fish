// Dayne
// Tweaks
// February 2024

save_tweaks_file :: (file_name : string) {
    builder : String_Builder;
    defer free_buffers(*builder);

    // Write to the buffer
    {
        append(*builder, "# Tweaks file\n\n");

        print_to_builder(*builder, "fullscreen %\n", graphics_context.fullscreen);

        print_to_builder(*builder, "sfx %\n", mix_levels[Sound_Category.GENERAL_SFX]);
        print_to_builder(*builder, "music %\n", mix_levels[Sound_Category.MUSIC]);
    }

    full_path := tprint("%/%.tweaks", tweaks_path, file_name);
    write_entire_file(full_path, *builder);
}

load_tweaks_file_and_apply_results :: (file_name : string) -> file_exists: bool {
    handler : Text_File_Handler;
    defer deinit(*handler);
    handler.do_version_number = false;

    full_path := tprint("%/%.tweaks", tweaks_path, file_name);
    start_file(*handler, file_name, full_path);
    if handler.failed return false;

    {
        line, found := consume_next_line(*handler);

        while found {
            successfully_split, left, right := split_from_left(line, #char " ");
            if !successfully_split {
                log_error("Problem parsing the tweaks file!\n");
                return false;
            }

            successfully_parsed : bool;
            if left == {
                case "fullscreen";
                    graphics_context.fullscreen, successfully_parsed = parse_bool(*right);
                    set_screen_mode_according_to_fullscreen_variable();

                case "sfx";
                    mix_levels[Sound_Category.GENERAL_SFX], successfully_parsed = parse_float(*right);

                case "music";
                    mix_levels[Sound_Category.MUSIC], successfully_parsed = parse_float(*right);
            }
            if !successfully_parsed {
                log_error("Problem parsing the tweaks file!\n");
                return false;
            }

            line, found = consume_next_line(*handler);
        }
    }

    return true;
}

//
//

apply_default_settings :: () {
    graphics_context.fullscreen = false;
    set_screen_mode_according_to_fullscreen_variable();

    default_mix :: float.[1.0, 1.0, 1.0, 1.0, 1.0];
    mix_levels[Sound_Category.GENERAL_SFX] = default_mix[Sound_Category.GENERAL_SFX];
    mix_levels[Sound_Category.MUSIC]       = default_mix[Sound_Category.MUSIC];
}
