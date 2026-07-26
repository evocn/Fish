// Dayne
// Guy (Entity)
// August 2024

Guy :: struct {
    using entity: Entity;
    kind = .GUY;
    
    name : string;

    using actor : Actor;

    personality : Personality;

    animation   : *Sprite_Animation;

    rarity : Rarity;

    biography : Biography;

    // State
    facing_left : bool;     @NoSerialize
    velocity    : Vector2;  @NoSerialize
}

initialize :: (using guy: *Guy) {
    facing_left = false;
    velocity = .{};
}

update :: (using guy: *Guy, dt: float) {
    // Personality update
    {
        update(*personality, guy, dt);

        update_from_gravity :: (using guy: *Guy, dt: float) {
            grounded := check_if_grounded(*guy.actor);
            if grounded then return;

            guy.velocity.y += game.GRAVITY * dt;
        }

        if !personality.current_whim.swimming {
            update_from_gravity(guy, dt);
        }
    }

    // Move
    {
        amount_to_move := velocity * dt;

        collided_x := move_x(*guy.actor, amount_to_move.x, null);
        if collided_x {
            if guy.personality.current_whim.bouncy_x then velocity.x = -velocity.x;
            else velocity.x = 0;
        }

        collided_y := move_y(*guy.actor, amount_to_move.y, null);
        if collided_y {
            if guy.personality.current_whim.bouncy_y then velocity.y = -velocity.y;
            else velocity.y = 0;
        }

        if collided_x || collided_y then play_sfx("bump", true);

        tank_collisions(*actor, *velocity);
    }


    update_visuals :: (using guy: *Guy, dt: float) {
        // Facing direction
        if velocity.x < 0.0 {
            facing_left = true;
        }
        else if velocity.x > 0.0 {
            facing_left = false;
        }
    }
    update_visuals(guy, dt);
}

draw :: (using guy: *Guy) {
    draw_sprite_relative_to_collider(
        collider, animation.sheet, animation.frame, facing_left
    );
}

draw_debug :: (using guy: *Guy) {
    draw(collider, color=debug.unique_color);
}


// Utilities

get_camera_centered_on_guy :: (guy: Guy) -> Pair {
    camera_center := 
        .{guy.x, guy.y}                                     // Start with the guy's bottom left corner
      + .{TILE_SIZE_IN_PIXELS / 2, TILE_SIZE_IN_PIXELS / 2} // Half the tile size to center on the main character
      + .{0, PIXEL_HEIGHT / 3}                              // Plus a little to bring the camera up a smidge
      - .{PIXEL_WIDTH / 2, PIXEL_HEIGHT / 2}                // Offset the camera to the bottom right corner
    ;

    return camera_center;
}


////////////////////////////////////////////////////////////////////////////////

Rarity :: enum #complete {
    COMMON;
    RARE;
    MYTHIC;
}

// Tweakable!
get_probability :: (rarity: Rarity) -> float {
    if #complete rarity == {
        case .COMMON; return 0.40;
        case .RARE;   return 0.25;
        case .MYTHIC; return 0.10;
    }
}

////////////////////////////////////////////////////////////////////////////////

Biography :: struct {
    facts : [..] string;
    quote : string;

    color : Color = white;
}
