// Dayne
// Game
// August 2024

Level :: struct {
    // State
    using grid : struct {
        width   :: 14;
        height  :: 8;

        tiles : [height * width] Tile;
    }

    pixel_extents :: Collider.{
        width  = grid.width *  TILE_SIZE_IN_PIXELS,
        height = grid.height * TILE_SIZE_IN_PIXELS,
        x = 0,
        y = 0,
    };
}

reset :: (level: *Level) {
    // @TODO
}

load_level_from_file :: (level: *Level, filename : string) {
    reset(level); 

    raw_text, success := read_entire_file(tprint("%/%.level", data_path, filename));
    stripped_newlines, line_count := replace(raw_text, "\r\n", "",, allocator=temp);
    assert(line_count == game.level.height, "Uh oh.. Problem with the text file.\n");

    for character, index : cast([]u8)stripped_newlines {
        new_tile := *level.tiles[index];

        new_tile.* = get_tile_from_catalogue(character - 48);
        new_tile.debug_color = random_color();

        if level.tiles[index].kind == .SOLID {
            tile_position := get_tile_position_from_level_index(game.level, index);
            new_tile.x = tile_position.x;
            new_tile.y = tile_position.y;

            array_add(*game.simulation.solids, *new_tile.solid);
        }
    }
}
