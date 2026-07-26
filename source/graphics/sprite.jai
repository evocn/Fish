// Dayne
// Sprite
// February 2024

Sprite :: struct {
    texture : Texture = ---;
    tile_width_in_pixels, tile_height_in_pixels : int;
    columns, rows : int;
    loaded := false;
}

draw_sprite :: (
                sprite : Sprite,
                pixel : Pair,
                frame: int = 0,
                scale_factor : int,
                horizontal_flip := false,
                use_color_override := false, color_override := white
               )
{
    shader := use_sprite_shader();

    assert(frame >= 0 && frame < (sprite.columns * sprite.rows));

    // Find the right uv coordinates for the texture.
    {
        col := frame % sprite.columns;
        row := frame / sprite.columns;

        spritesheet_offset := Vector2.{col / cast(float)sprite.columns, row / cast(float)sprite.rows};
        set_vec2(shader, "spritesheet_offset", spritesheet_offset);
        relative_sheet_scale := Vector2.{1.0 / sprite.columns, 1.0 / sprite.rows};
        set_vec2(shader, "relative_sheet_scale", relative_sheet_scale);
    }

    // Scale / Translate for the screen
    {
        model := Matrix4_Identity;
            x_translation := pixel.x / cast(float)PIXEL_WIDTH;
            y_translation := pixel.y / cast(float)PIXEL_HEIGHT;
            translation_vector := Vector3.{x_translation, y_translation, 0};

            x_scale := scale_factor / (cast(float)PIXEL_WIDTH  / sprite.tile_width_in_pixels);
            y_scale := scale_factor / (cast(float)PIXEL_HEIGHT / sprite.tile_height_in_pixels);
            scale_vector := Vector3.{x_scale, y_scale, 1};

            translate(*model, translation_vector);
            scale(*model, scale_vector);
        set_mat4(shader, "model", model);
    }


    set_bool(shader, "horizontal_flip", horizontal_flip);


    // @TODO?
    set_vec4(shader, "color_override", color_override);
    set_bool(shader, "use_color_override", use_color_override);


    bind(sprite.texture, 0);
    draw_quad(graphics_context.quad);
}

////////////////////////////////////////////////////////////////////////////////

load_sprite :: (full_path: string) -> Sprite {
    sprite : Sprite;
    success : bool;

    sprite.texture, success = load_texture(full_path);
    if success {
        sprite.loaded = true;
    }
    else {
        log_error("Unable to load sprite at %\n", full_path);
    }

    sprite.tile_width_in_pixels  = sprite.texture.width;
    sprite.tile_height_in_pixels = sprite.texture.height;
    sprite.columns = 1;
    sprite.rows = 1;

    return sprite;
}

load_sheet :: (full_path : string, tile_width_in_pixels : int, tile_height_in_pixels : int) -> Sprite {
    sprite := load_sprite(full_path);

    sprite.tile_width_in_pixels  = tile_width_in_pixels;
    sprite.tile_height_in_pixels = tile_height_in_pixels;
    sprite.columns = sprite.texture.width  / tile_width_in_pixels;
    sprite.rows    = sprite.texture.height / tile_height_in_pixels;

    return sprite;
}
