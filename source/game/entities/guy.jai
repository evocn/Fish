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

    directionality : enum {
        LEFT_RIGHT;
        FOUR_WAY;
    }

    // State
    facing_left : bool;     @NoSerialize
    facing_down : bool;     @NoSerialize
    velocity    : Vector2;  @NoSerialize
    grounded    : bool = true;
}

initialize :: (using guy: *Guy) {
}

update :: (using guy: *Guy, dt: float) {
    // Personality update
    {
        update(*personality, guy, dt);

        update_from_gravity :: (using guy: *Guy, dt: float) {
            previously_grounded := grounded;

            grounded = check_if_grounded(*guy.actor);
            if !grounded {
                guy.velocity.y += game.GRAVITY * dt;
            }

            // @HACK
            if grounded && !previously_grounded && guy.y < 32 {
                a: Allocator;
                a.proc = flat_pool_allocator_proc;
                a.data = *game.arena;
                new_sys := make_dust_cloud(bottom_middle_of_collider(guy.collider),, a);
                array_add(*game.entities, xx new_sys);
            }
        }

        if !personality.current_whim.swimming {
            update_from_gravity(guy, dt);
        }
    }

    // jet streams
    {
        for entity : game.entities {
            if entity.kind != .JET continue;
            jet := cast(*Jet)entity;
            if collision(collider, jet.collider) {
                guy.velocity.y += jet.acceleration;
            }
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
        if directionality == {
            case .LEFT_RIGHT;
                facing_left = velocity.x < 0;

            case .FOUR_WAY;
                facing_left = velocity.x > 0;
                facing_down = velocity.y > 0;
        }
    }
    update_visuals(guy, dt);
}

draw :: (using guy: *Guy) {
    draw_sprite_relative_to_collider(
        collider, animation.sheet, animation.frame, facing_left, facing_down,
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
        case .COMMON; return 0.80;
        case .RARE;   return 0.60;
        case .MYTHIC; return 0.40;
    }
}

////////////////////////////////////////////////////////////////////////////////

Biography :: struct {
    facts : [..] string;

    color : Color = white;
}
