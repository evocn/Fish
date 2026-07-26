// Dayne
// Graphics Drawing Functions
// August 2024

draw_sprite_relative_to_collider :: (
    using collider : Collider,
    sheet: string,
    frame := 0,
    facing_left := false
)
{
    sprite := table_find_pointer(*graphics_context.sheets, sheet);
    if !sprite {
        log_error("Couldn't load spritesheet % for drawing.\n", sheet);
        return;
    }

    screen_pixel := world_space_to_screen_pixel(xx x, xx y);

    bottom_left_corner_of_sprite :=
          screen_pixel    // Bottom left corner of collider
        + .{width / 2, 0} // Gets us the center bottom of collider
        - .{sprite.tile_width_in_pixels / 2, 0} // Bottom left corner!
    ;

    scale := screen_pixel_zoom();

    draw_sprite(
        sprite,
        frame = frame,
        pixel = bottom_left_corner_of_sprite,

        scale_factor = scale,

        horizontal_flip = facing_left,

        use_color_override = false,
    );
}

world_space_to_screen_pixel :: (x: int, y: int) -> pixel: Pair {
    pixel: Pair;

    pixel.x = x;
    pixel.y = y;

    // Camera Transform
    {
        pixel -= game.camera;
        pixel = game.camera_zoom * pixel;
    }

    return pixel;
}

screen_pixel_zoom :: () -> zoom: int {
    return game.camera_zoom;
}

////////////////////////////////////////////////////////////////////////////////

// Entity
draw_tile :: (tile: Tile, place : Pair) {
    screen_position := world_space_to_screen_pixel(place.x, place.y);
    scale := screen_pixel_zoom();
    draw_tile_at(tile, screen_position, scale);
}

draw_tile_at :: (tile: Tile, at: Pair, scale: int) {
    sprite := table_find_pointer(*graphics_context.sheets, "fishes");
    if !sprite {
        log_error("Couldn't load tile spritesheet.\n");
        return;
    }

    draw_sprite(
        sprite,
        frame = tile.sprite,
        pixel = at,

        scale_factor = scale,

        horizontal_flip = false,

        use_color_override = false,
    );
}

// Menu
draw_menu :: (using menu: Menu) {
    k := 10;

    for elements {
        draw_menu_element(it, PIXEL_HEIGHT - (it_index + 1) * k, color=it.usual_color);
    }

    // Draw selected element over it.
    if elements.count {
        hovering := *elements[element_index];
        draw_menu_element(hovering.*, PIXEL_HEIGHT - (element_index + 1) * k, color=hovering.*.hover_color);
    }
}

draw_menu_element :: (using element: *Menu_Element, height : int, color := white) {
    if kind == {
        case .GO;
            using cast(*Menu_Element_Go)element;
            draw_text(name, 1, height, color=color);

        case .CHECKBOX;
            using cast(*Menu_Element_Checkbox)element;
            str := "Off";
            if value.* then str = "On";
            draw_text(tprint("% - %", name, str), 1, height, color=color);

        case .SLIDER;
            using cast(*Menu_Element_Slider)element;
            draw_text(tprint("% - %", name, value.*), 1, height, color=color);
    }
}


// Clock
draw_clock_readout :: () {
    using t := time();

    clock_readout : string;
    {
        am_pm_string : string;
        if hour < 12 {
            am_pm_string = "am";
        }
        else {
            am_pm_string = "pm";
        }

        hour_in_twelve_hour_time := hour;
        if hour_in_twelve_hour_time > 12 {
            hour_in_twelve_hour_time -= 12;
        }

        new_context := context;
        format_int := *new_context.print_style.default_format_int;
        format_int.minimum_digits = 2;

        push_context new_context {
            clock_readout = tprint("%:% %", hour_in_twelve_hour_time, minute, am_pm_string);
        }
    }

    color : Color;
    {
        if hour < 3 {
            color = pink;
        }
        else if hour < 6 {
            color = purple;
        }
        else if hour < 9 {
            color = yellow;
        }
        else if hour < 12 {
            color = green;
        }
        else if hour < 15 {
            color = teal;
        }
        else if hour < 18 {
            color = blue;
        }
        else if hour < 21 {
            color = red;
        }
        else if hour < 24 {
            color = gray;
        }
        else {
            "What the fuck?";
        }
    }

    draw_colored_quad(
        x = 0,
        y = 0,
        width  = 34,
        height = 7,
        color  = black,
    );

    draw_text(
        clock_readout, 
        x = 1,
        y = 1,
        alignment   = Alignment.LEFT,
        progress    = -1,
        font        = .SMALL,
        color       = color,
    );
}


draw :: (collider: Collider, color : Color, outline_color := white) {
    screen_position := world_space_to_screen_pixel(collider.x, collider.y);
    scale := screen_pixel_zoom();
    
    draw_colored_quad(
        xx screen_position.x, xx screen_position.y,
        xx collider.width * scale, xx collider.height * scale,
        color=color
    );
}

