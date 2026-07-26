// Dayne
// Game
// August 2024

#load "level.jai";

#load "entity.jai";
//#load "entity_serialization.jai";
#load "tile.jai";

#load "personality.jai";
#load "behavior.jai";
#load "schedule.jai";

#load "sprite_animation.jai";

#load "entities/test.jai";
#load "entities/guy.jai";
#load "entities/particle_system.jai";
#load "entities/toy.jai";
#load "entities/food.jai";

#load "collisions/simulation.jai";

#load "interaction.jai";

Game :: struct {
    using constants : struct {
        GRAVITY :: -50.0;
    }

    using data : struct {
        guys : [..] *Guy;
    }

    player : Player_Interface;

    level : Level;
    entities : [..] *Entity;

    cursor : struct {
        state : Cursor_State;
    }

    simulation: Simulation;

    camera: Pair;
    camera_zoom : int;

    focused_guy: *Guy;

    using internals : struct {
        arena : Flat_Pool;
    }
}


simulate :: (using game: *Game, dt: float) {
    {
        using player.input;

        if      up.is_held      cursor.state = .PET;
        else if left.is_held    cursor.state = .SNAP;
        else if right.is_held   cursor.state = .SLEEP;
        else                    cursor.state = .NEUTRAL;
    }

    for entity : entities {
        update(entity, dt);
    }

    if focused_guy {
        camera_zoom = 2;

        running_camera : Pair;
        {
            running_camera = .{focused_guy.x, focused_guy.y}; // guy in bottom left.
            running_camera += .{xx (-1 * 1.4 * TILE_SIZE_IN_PIXELS), -1 * 1 * TILE_SIZE_IN_PIXELS}; // center them in the middle left of the screen

            clamp(running_camera.x, 0, 1000);
        }
        camera = running_camera;
    }
    else {
        camera = .{};
        camera_zoom = 1;
    }

    rainbow_color = update_rainbow_color(dt);
}


initialize :: (game: *Game) {
    load_level_from_file(*game.level, "1");

    game.camera = .{};
    game.camera_zoom = 1;

    // Entities
    {
        particle_system : *Particle_System = xx new_entity(.PARTICLE_SYSTEM);
        {
            using particle_system;
        }
        array_add(*game.entities, xx particle_system);

        toy : *Toy = xx new_entity(.TOY);
        {
            using toy;

            name = "anchor";

            x = 128;
            y = 16;
            width  = 32;
            height = 32;

            {
                animation = New(Sprite_Animation);
                {
                    using animation;
                    sheet = "Anchor";
                    frame_count = 1;
                }
            }
        }
        array_add(*game.entities, xx toy);

        kelp : *Toy = xx new_entity(.TOY);
        {
            using kelp;

            name = "kelp";

            x = 32;
            y = 16;
            width  = 16;
            height = 16;

            {
                animation = New(Sprite_Animation);
                {
                    using animation;
                    sheet = "kelp";
                    frame_count = 1;
                }
            }
        }
        array_add(*game.entities, xx kelp);

        food : *Food = xx new_entity(.FOOD);
        {
            using food;

            x = 40;
            y = 112;
        }
        array_add(*game.entities, xx food);

        // Load Guys

        frog : *Guy = xx new_entity(.GUY);
        {
            using frog;

            name = "frog";

            rarity = .COMMON;

            x = 100;
            y = 16;
            width  = 14;
            height = 14;

            {
                using personality;

                idle := New(Sprite_Animation);
                {
                    using idle;
                    sheet = "Frog-Idle";
                    frame_count = 8;
                    speed = 5.0;
                }

                walk := New(Sprite_Animation);
                {
                    using walk;
                    sheet = "Frog-Walk";
                    frame_count = 4;
                    speed = 7;
                }

                sleep := New(Sprite_Animation);
                {
                    using sleep;
                    sheet = "Frog-Sleep";
                    frame_count = 15;
                    speed = 10.0;
                }

                shock := New(Sprite_Animation);
                {
                    using shock;
                    sheet = "Frog-Shock";
                    frame_count = 8;
                    speed = 12.0;
                }

                heart := New(Sprite_Animation);
                {
                    using heart;
                    sheet = "Frog-Heart";
                    frame_count = 11;
                    speed = 10.0;
                }

                swim := New(Sprite_Animation);
                {
                    using swim;
                    sheet = "Frog-Swim";
                    frame_count = 5;
                    speed = 6.0;
                }

                jump := New(Sprite_Animation);
                {
                    using jump;
                    sheet = "Frog-Jump";
                    frame_count = 5;
                    speed = 30.0;
                }

                charge := New(Sprite_Animation);
                {
                    using charge;
                    sheet = "Frog-Charge";
                    frame_count = 1;
                }

                fly := New(Sprite_Animation);
                {
                    using fly;
                    sheet = "Frog-Fly";
                    frame_count = 1;
                }

                land := New(Sprite_Animation);
                {
                    using land;
                    sheet = "Frog-Land";
                    frame_count = 7;
                    speed = 50;
                }

                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 5;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Wander_Floor);
                    b.animation = walk;
                    b.idle_animation = idle;

                    b.bouncy_x = true;

                    b.minimum_duration = 8;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Swim_Upward);
                    b.animation = swim;

                    b.speed = 25.0;

                    b.swimming = true;
                    b.bouncy_x = true;
                    b.bouncy_y = false;

                    b.minimum_duration = 10;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Jump);
                    b.animation = jump;
                    b.charge_animation = charge;
                    b.flight_animation = fly;
                    b.land_animation = land;

                    b.charge_time = 1.0;

                    b.swimming = false;
                    b.bouncy_x = true;
                    b.bouncy_y = false;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = sleep;
                }

                {
                    shock_behavior = xx New(Behavior_React);
                    using shock_behavior;
                    animation = shock;
                }

                {
                    heart_behavior = xx New(Behavior_React);
                    using heart_behavior;
                    animation = heart;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                animation = idle;

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "favorite food: fleas");
                array_add(*facts, "can walk and swim");
                array_add(*facts, "6 years old");
                array_add(*facts, "has over 10,000 children");

                quote = "ribbit";

                color = green;
            }
        }

        tako : *Guy = xx new_entity(.GUY);
        {
            using tako;

            name = "tako";

            rarity = .MYTHIC;

            x = 32;
            y = 16;
            width  = 15;
            height = 15;

            {
                using personality;


                idle := New(Sprite_Animation);
                {
                    using idle;
                    sheet = "Tako-Idle";
                    frame_count = 9;
                    speed = 10.0;
                }

                walk := New(Sprite_Animation);
                {
                    using walk;
                    sheet = "Tako-Walk";
                    frame_count = 7;
                    speed = 10.0;
                }

                sleep := New(Sprite_Animation);
                {
                    using sleep;
                    sheet = "Tako-Sleep";
                    frame_count = 9;
                    speed = 10.0;
                }

                shock := New(Sprite_Animation);
                {
                    using shock;
                    sheet = "Tako-Shock";
                    frame_count = 13;
                    speed = 20.0;
                }

                heart := New(Sprite_Animation);
                {
                    using heart;
                    sheet = "Tako-Heart";
                    frame_count = 16;
                    speed = 8.0;
                }

                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 7;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Wander_Floor);
                    b.animation = walk;
                    b.idle_animation = idle;

                    b.bouncy_x = true;

                    b.minimum_duration = 15;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = sleep;
                }

                {
                    shock_behavior = xx New(Behavior_React);
                    using shock_behavior;
                    animation = shock;
                }

                {
                    heart_behavior = xx New(Behavior_React);
                    using heart_behavior;
                    animation = heart;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                animation = idle;

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "professional chef");
                array_add(*facts, "favorite food: souffle");
                array_add(*facts, "least favorite: peas");

                quote = "your order?";

                color = green;
            }
        }

        clam : *Guy = xx new_entity(.GUY);
        {
            using clam;

            name = "clam";

            rarity = .RARE;

            x = 162;
            y = 80;
            width  = 12;
            height = 6;

            {
                using personality;

                idle := New(Sprite_Animation);
                {
                    using idle;
                    sheet = "Clam-Idle";
                    frame_count = 1;
                    speed = 1.0;
                }

                sleep := New(Sprite_Animation);
                {
                    using sleep;
                    sheet = "Clam-Sleep";
                    frame_count = 2;
                    speed = 1.2;
                }

                shock := New(Sprite_Animation);
                {
                    using shock;
                    sheet = "Clam-Shock";
                    frame_count = 20;
                    speed = 15.0;
                }

                heart := New(Sprite_Animation);
                {
                    using heart;
                    sheet = "Clam-Heart";
                    frame_count = 4;
                    speed = 10;
                }

                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 10;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = sleep;
                }

                {
                    shock_behavior = xx New(Behavior_React);
                    using shock_behavior;
                    animation = shock;
                }

                {
                    heart_behavior = xx New(Behavior_React);
                    using heart_behavior;
                    animation = heart;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                animation = idle;

                {
                    schedule.hours = Plan.[
                        .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "a real homebody");
                array_add(*facts, "only comes out sometimes");
                array_add(*facts, "watches lots of movies");
                array_add(*facts, "favorite movie: 'Rocky'");

                quote = "...";

                color = purple;
            }
        }

        jelly : *Guy = xx new_entity(.GUY);
        {
            using jelly;

            name = "jelly";

            rarity = .COMMON;

            x = 128;
            y = 16;
            width  = 16;
            height = 16;

            {
                using personality;

                idle := New(Sprite_Animation);
                {
                    using idle;
                    sheet = "Jelly-Idle";
                    frame_count = 10;
                    speed = 7.0;
                }

                walk := New(Sprite_Animation);
                {
                    using walk;
                    sheet = "Jelly-Walk";
                    frame_count = 8;
                    speed = 10.0;
                }

                sleep := New(Sprite_Animation);
                {
                    using sleep;
                    sheet = "Jelly-Sleep";
                    frame_count = 14;
                    speed = 10.0;
                }

                shock := New(Sprite_Animation);
                {
                    using shock;
                    sheet = "Jelly-Shock";
                    frame_count = 5;
                    speed = 20;
                }

                heart := New(Sprite_Animation);
                {
                    using heart;
                    sheet = "Jelly-Heart";
                    frame_count = 20;
                    speed = 10.0;
                }

                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 7;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Wander_Floor);
                    b.animation = walk;
                    b.idle_animation = idle;

                    b.bouncy_x = true;

                    b.minimum_duration = 4;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = sleep;
                }

                {
                    shock_behavior = xx New(Behavior_React);
                    using shock_behavior;
                    animation = shock;
                }

                {
                    heart_behavior = xx New(Behavior_React);
                    using heart_behavior;
                    animation = heart;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                animation = idle;

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "sticky");
                array_add(*facts, "don't get too close");

                quote = "zzt";

                color = teal;
            }
        }

        blowfish : *Guy = xx new_entity(.GUY);
        {
            using blowfish;

            name = "blowfish";

            rarity = .COMMON;

            x = 64;
            y = 64;
            width  = 14;
            height = 14;

            {
                using personality;

                idle := New(Sprite_Animation);
                {
                    using idle;
                    sheet = "Blowfish-Idle";
                    frame_count = 8;
                    speed = 7.0;
                }

                walk := New(Sprite_Animation);
                {
                    using walk;
                    sheet = "Blowfish-Walk";
                    frame_count = 5;
                    speed = 10.0;
                }

                bounce := New(Sprite_Animation);
                {
                    using bounce;
                    sheet = "Blowfish-Bounce";
                    frame_count = 20;
                    speed = 10.0;
                }

                heart := New(Sprite_Animation);
                {
                    using heart;
                    sheet = "Blowfish-Happy";
                    frame_count = 10;
                    speed = 10.0;
                }

                sleep := New(Sprite_Animation);
                {
                    using sleep;
                    sheet = "Blowfish-Sleep";
                    frame_count = 21;
                    speed = 10.0;
                }

                shock := New(Sprite_Animation);
                {
                    using shock;
                    sheet = "Blowfish-Shock";
                    frame_count = 1;
                    speed = 0.1;
                }

                {
                    b := New(Behavior_Wander);
                    b.animation = walk;
                    b.idle_animation = idle;

                    b.speed = 15.0;

                    b.swimming = true;
                    b.bouncy_x = true;
                    b.bouncy_y = true;

                    b.minimum_duration = 10;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Swim);
                    b.animation = walk;

                    b.speed = 25;

                    b.swimming = true;
                    b.bouncy_x = true;
                    b.bouncy_y = true;

                    b.minimum_duration = 5;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Sleep);
                    b.animation = sleep;

                    b.swimming = true;

                    sleep_behavior = xx b;
                }

                {
                    b := New(Behavior_Bounce);
                    b.animation = bounce;

                    b.swimming = true;
                    b.bouncy_x = true;
                    b.bouncy_y = true;

                    b.minimum_duration = 5;

                    shock_behavior = xx b;
                }

                {
                    b := New(Behavior_React);
                    b.animation = heart;

                    heart_behavior = xx b;
                }

                {
                    b := New(Behavior_Eat);
                    b.animation = idle;

                    eat_behavior = xx b;
                }

                animation = idle;

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "curious, but hesitant");
                array_add(*facts, "does not like surprises");
                array_add(*facts, "dreams of a trip someday");
                array_add(*facts, "favorite person: June");

                quote = "blub";

                color = yellow;
            }
        }

        blob : *Guy = xx new_entity(.GUY);
        {
            using blob;

            name = "blob";

            rarity = .RARE;

            x = 32;
            y = 96;
            width  = 16;
            height = 16;

            {
                using personality;

                idle := New(Sprite_Animation);
                {
                    using idle;
                    sheet = "Blobfish-Idle";
                    frame_count = 1;
                    speed = 0.0;
                }

                blink := New(Sprite_Animation);
                {
                    using blink;
                    sheet = "Blobfish-Blink";
                    frame_count = 16;
                    speed = 0.1;
                }

                yawn := New(Sprite_Animation);
                {
                    using yawn;
                    sheet = "Blobfish-OpenMouth";
                    frame_count = 40;
                    speed = 0.1;
                }

                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 100;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Idle);
                    b.animation = yawn;

                    b.minimum_duration = 10;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Idle);
                    b.animation = blink;

                    b.minimum_duration = 10;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = idle;
                }

                {
                    shock_behavior = xx New(Behavior_React);
                    using shock_behavior;
                    animation = idle;
                }

                {
                    heart_behavior = xx New(Behavior_React);
                    using heart_behavior;
                    animation = idle;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                animation = idle;

                {
                    schedule.hours = Plan.[
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "?????????????????????????????????????");

                quote = "???";

                color = pink;
            }
        }

        crab : *Guy = xx new_entity(.GUY);
        {
            using crab;

            name = "crab";

            rarity = .COMMON;

            x = 112;
            y = 16;
            width  = 12;
            height = 12;

            {
                using personality;

                idle := New(Sprite_Animation);
                {
                    using idle;
                    sheet = "Crab-Idle";
                    frame_count = 10;
                    speed = 10;
                }

                walk := New(Sprite_Animation);
                {
                    using walk;
                    sheet = "Crab-Walk";
                    frame_count = 4;
                    speed = 10;
                }

                heart := New(Sprite_Animation);
                {
                    using heart;
                    sheet = "Crab-Heart";
                    frame_count = 1;
                    speed = 1;
                }

                shock := New(Sprite_Animation);
                {
                    using shock;
                    sheet = "Crab-Shock";
                    frame_count = 1;
                    speed = 1;
                }

                sleep := New(Sprite_Animation);
                {
                    using sleep;
                    sheet = "Crab-Sleep";
                    frame_count = 4;
                    speed = 1;
                }

                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 10;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Wander_Floor);
                    b.animation = walk;
                    b.idle_animation = idle;

                    b.minimum_duration = 10;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = sleep;
                }

                {
                    shock_behavior = xx New(Behavior_React);
                    using shock_behavior;
                    animation = shock;
                }

                {
                    heart_behavior = xx New(Behavior_React);
                    using heart_behavior;
                    animation = heart;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                animation = idle;

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, 
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                    ];
                }
            }

            {
                using biography;

                // @TODO
                //array_add(*facts, "");

                quote = "sup";

                color = orange;
            }
        }

        {
            array_add(*game.guys, frog);
            array_add(*game.guys, tako);
            array_add(*game.guys, clam);
            array_add(*game.guys, jelly);
            array_add(*game.guys, blowfish);
            array_add(*game.guys, blob);
            array_add(*game.guys, crab);
        }

        genocide(game);

        seed := generate_seed_from_date_and_hour();
        populate(game, seed);
        //populate_everyone(game);
    }
}

genocide :: (using game: *Game) {
    for entities if it.kind == .GUY then remove it;
}

populate_everyone :: (using game: *Game) {
    for guy : guys {
        array_add(*entities, xx guy);
        array_add(*simulation.actors, *guy.actor);
    }
}

populate :: (using game: *Game, seed: Random_State) {
    guys_in_the_tank : int;
    for guy : guys {
        roll := random_get_zero_to_one(*seed);
        if roll <= get_probability(guy.rarity) {
            array_add(*game.entities, xx guy);
            array_add(*game.simulation.actors, *guy.actor);
            guys_in_the_tank += 1;
        }
    }

    // Gotta have at least one...
    if guys_in_the_tank == 0 {
        guy := random_choice(guys, *seed);
        array_add(*game.entities, xx guy);
        array_add(*game.simulation.actors, *guy.actor);
        guys_in_the_tank += 1;
    }
}

// Seed the population generator with the hour and the date.
// This way, it doesn't feel like you're just rolling the dice every time you open the app.
generate_seed_from_date_and_hour :: () -> Random_State {
    random_state : Random_State;

    t := time();
    seed : u64 = cast(u64)t.hour + (cast(u64)t.day_of_week_starting_at_0 << 8);

    random_seed(*random_state, seed);

    return random_state;
}

generate_seed :: () -> Random_State {
    random_state : Random_State;

    t := time();

    seed : u64 = cast(u64)t.millisecond;

    random_seed(*random_state, seed);

    return random_state;
}
