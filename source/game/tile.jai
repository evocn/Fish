// Dayne
// Tile
// August 2024

Tile :: struct {
    using properties : Tile_Properties;

    using solid : Solid;
    width   = TILE_SIZE_IN_PIXELS;
    height  = TILE_SIZE_IN_PIXELS;

    debug_color : Color;
}

Tile_Properties :: struct {
    catalogue_index : int;

    kind : Tile_Kind;

    sprite : int;
}

Tile_Kind :: enum {
    EMPTY;
    SOLID;
}

// Utilities
get_tile_position_from_level_index :: (level: Level, index: int) -> Pair {
    col := index % level.width;
    row := index / level.width;

    return .{col * TILE_SIZE_IN_PIXELS, row * TILE_SIZE_IN_PIXELS};
}

// Catalogue

tile_catalogue := Tile_Properties.[
    .{
        catalogue_index = 0,
        kind = .EMPTY,
        sprite = 1023,
    },

    .{
        catalogue_index = 1,
        kind = .SOLID,
        sprite = 337,
    },

    .{
        catalogue_index = 2,
        kind = .SOLID,
        sprite = 336,
    },
];

get_tile_from_catalogue :: (catalogue_index : int) -> Tile {
    new_tile : Tile;
    new_tile.properties = tile_catalogue[catalogue_index];

    if #complete new_tile.properties.kind == {
        case .EMPTY;

        case .SOLID;
    }

    return new_tile;
}
