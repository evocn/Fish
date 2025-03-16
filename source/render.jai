// Dayne
// Render
// August 2024

render :: (game: Game, menu: Menu) {
    // render everything in this block to the framebuffer.
    {
        glBindFramebuffer(GL_FRAMEBUFFER, graphics_context.fbo);
        glViewport(0, 0, PIXEL_WIDTH, PIXEL_HEIGHT);
        glClearColor(black.x, black.y, black.z, 1);
        glClear(GL_COLOR_BUFFER_BIT);

        if #complete program_state.current_scene == {
            case .TITLE;
                draw_title_screen();
                draw_version_indicator();
                draw_controls();

            case .GAME;
                draw_game(game);
                draw_user_interface(game);

            case .MENU;
                draw_menu(menu);
                draw_title_screen();
                draw_version_indicator();
                draw_controls();

            case .EDITOR;
                draw_game(game);
                // editor rendering is contained in editor.jai.
        }
    }

    render_framebuffer_to_screen();
}

draw_user_interface :: (game: Game) {
    draw_clock_readout();

    if game.player.input.mouse_active && !game.focused_guy {
        mouse_position := game.player.input.mouse_position;
        draw_mouse_cursor(mouse_position, game.cursor.state);
    }

    if game.focused_guy {
        blurb_width := PIXEL_WIDTH / 2;
        blurb_start := PIXEL_WIDTH - blurb_width;

        draw_colored_quad(blurb_start, 0, blurb_width, PIXEL_HEIGHT, color = black);

        {
            using game.focused_guy.biography;

            text_start_x := blurb_start + 8;
            text_start_y := PIXEL_HEIGHT - 24;

            k := 0;

            draw_text(
                game.focused_guy.name,
                x = text_start_x,
                y = text_start_y - k,
                alignment   = Alignment.LEFT,
                progress    = -1,
                font        = .MAIN,
                color       = color,
            );

            k += 16;

            for fact : facts {
                draw_text(
                    fact,
                    x = text_start_x,
                    y = text_start_y - k,
                    alignment   = Alignment.LEFT,
                    progress    = -1,
                    font        = .SMALL,
                    color       = color,
                );

                k += 10;
            }

        }

        draw_mouse_cursor(.{PIXEL_WIDTH / 2 + 16, 16}, game.cursor.state);
    }
}

draw_mouse_cursor :: (position : Pair, cursor_state: Cursor_State) {
    sprite := table_find_pointer(*graphics_context.sheets, "Cursor");
    if !sprite {
        log_error("Couldn't load cursor spritesheet.\n");
        return;
    }

    index : int;
    if #complete cursor_state == {
        case .NEUTRAL;  index = 0;
        case .PET;      index = 1;
        case .SNAP;     index = 2;
        case .SLEEP;    index = 3;
    }

    draw_sprite(
        sprite,
        frame = index,
        pixel = position - .{0, 16},

        scale_factor = 1,

        horizontal_flip = false,

        use_color_override = false,
    );
}

draw_title_screen :: () {
    draw_text(
        "Fish Tank",
        x = PIXEL_WIDTH - 10,
        y = 80,
        alignment   = Alignment.RIGHT,
        progress    = -1,
        font        = .MAIN,
        color       = blue,
    );

    draw_text(
        "Showcase mode",
        x = PIXEL_WIDTH - 10,
        y = 60,
        alignment   = Alignment.RIGHT,
        progress    = -1,
        font        = .SMALL,
        color       = yellow,
    );

    draw_text(
        "March 2025",
        x = PIXEL_WIDTH - 10,
        y = 40,
        alignment   = Alignment.RIGHT,
        progress    = -1,
        font        = .SMALL,
        color       = gray,
    );
}

draw_version_indicator :: () {
    draw_text(
        tprint("version %", VERSION),
        x = 1,
        y = 1,
        alignment = Alignment.LEFT,
        progress = -1,
        font = .SMALL,
        color = green,
    );
}

draw_controls :: () {
    draw_text(
        "Mouse to select",
        x = 3,
        y = 30,
        alignment   = Alignment.LEFT,
        progress    = -1,
        font        = .SMALL,
        color       = gray,
    );

    draw_text(
        "A/W/D + click for interaction",
        x = 3,
        y = 20,
        alignment   = Alignment.LEFT,
        progress    = -1,
        font        = .SMALL,
        color       = gray,
    );

    draw_text(
        "click to start!",
        x = 3,
        y = 10,
        alignment   = Alignment.LEFT,
        progress    = -1,
        font        = .SMALL,
        color       = white,
    );
}

////////////////////////////////////////////////////////////////////////////////


draw_game :: (game : Game) {
    {
        sprite := table_find_pointer(*graphics_context.sheets, "Foliage");
        if !sprite then log_error("Couldn't load foliage spritesheet.\n");

        draw_sprite(
            sprite,
            frame = 0,
            pixel = world_space_to_screen_pixel(0, 0),

            scale_factor = screen_pixel_zoom(),

            horizontal_flip = false,
            use_color_override = false,
        );
    }

    // Z Sort entities
    {
        comparison :: (a: *Entity, b: *Entity) -> int { 
            if a.z_index > b.z_index        return 1;
            else if a.z_index < b.z_index   return -1;
            else return b.id - a.id;
        }
        quick_sort(game.entities, comparison);
    }

    // Draw Entities behind stage
    for entity : game.entities {
        if entity.z_index > 0 then break;
        draw(entity);
    }

    // Draw Level
    for tile, index : game.level.tiles {
        if tile.kind == .EMPTY then continue;

        pixel : Pair;

        world_column := index % game.level.width;
        world_row    := index / game.level.width;

        pixel.x = world_column * TILE_SIZE_IN_PIXELS;
        pixel.y = world_row    * TILE_SIZE_IN_PIXELS;

        draw_tile(tile, pixel);
    }

    // Draw Entities in front of stage
    for entity : game.entities {
        if entity.z_index < 0 then continue;
        draw(entity);
    }


    // Special Code per player state?
    if game.player.state == {
        case .DEFAULT;
    }


    // Debug Overlays
    if program_state.mode == .DEBUG {
        // Draw Colliders
        {
            for tile : game.level.tiles {
                draw(tile.collider, color=tile.debug_color);
            }

            for entity : game.entities {
                draw_debug(entity);
            }
        }
    }
}
