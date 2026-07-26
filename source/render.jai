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

            case .GAME;
                draw_game(game);
                draw_user_interface(game);

            case .MENU;
                draw_menu(menu);
                draw_version_indicator();
                draw_title_screen();

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

            draw_text(
                tprint("\"%\"", quote),
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
    }
}

draw_mouse_cursor :: (position : Pair, cursor_state: Cursor_State) {
    sprite := table_find_pointer(*graphics_context.sheets, "cursor");
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
        "June's Fish Tank",
        x = PIXEL_WIDTH / 2,
        y = 80,
        alignment   = Alignment.CENTER,
        progress    = -1,
        font        = .MAIN,
        color       = blue,
    );

    draw_text(
        "A dream fulfilled!",
        x = PIXEL_WIDTH / 2,
        y = 50,
        alignment   = Alignment.CENTER,
        progress    = -1,
        font        = .SMALL,
        color       = yellow,
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

////////////////////////////////////////////////////////////////////////////////

draw_game :: (game : Game) {
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

    // Draw Entities
    {
        // Z Sort em real quick
        {
            comparison :: (a: *Entity, b: *Entity) -> int { 
                if a.z_index > b.z_index        return 1;
                else if a.z_index < b.z_index   return -1;
                else return b.id - a.id;
            }
            quick_sort(game.entities, comparison);
        }

        for entity : game.entities {
            draw(entity);
        }
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
