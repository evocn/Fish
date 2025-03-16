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
#load "entities/jet.jai";

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

            one_shot = false;
            lifetime_min = 1.0;
            lifetime_max = 10.0;
            initial_velocity_min = .{0, 10};
            initial_velocity_max = .{0, 30};
            initial_acceleration_min = .{0, 0};
            initial_acceleration_max = .{0, -0.1};

            custom_initializer = background_particle_initializer;
        }
        array_add(*game.entities, xx particle_system);

        toy : *Toy = xx new_entity(.TOY);
        {
            using toy;

            name = "anchor";

            x = 30;
            y = 15;
            width  = 32;
            height = 32;

            animation = make_animation("Anchor");
        }
        array_add(*game.entities, xx toy);

        /*
        chest : *Toy = xx new_entity(.TOY);
        {
            using chest;

            name = "chest";

            x = 180;
            y = 15;
            width  = 16;
            height = 16;

            animation = make_animation("Chest");
        }
        array_add(*game.entities, xx chest);
        */

        kelp : *Toy = xx new_entity(.TOY);
        {
            using kelp;

            name = "kelp";

            x = 64;
            y = 11;
            width  = 32;
            height = 64;

            animation = make_animation("Seaweed");
        }
        array_add(*game.entities, xx kelp);

        /*
        food : *Food = xx new_entity(.FOOD);
        {
            using food;

            x = 40;
            y = 112;
        }
        array_add(*game.entities, xx food);
        */

        jet : *Jet = xx new_entity(.JET);
        {
            using jet;

            z_index = -100;

            x = 160;
            y = 15;
            width = 10;
            height = 20;

            animation = make_animation("Bubbles", speed = 10.0);
        }
        array_add(*game.entities, xx jet);

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

                idle := make_animation("Frog-Idle",     speed = 5.0);
                walk := make_animation("Frog-Walk",     speed = 7.0);
                sleep := make_animation("Frog-Sleep",   speed = 10.0);
                shock := make_animation("Frog-Shock",   speed = 12.0);
                heart := make_animation("Frog-Heart",   speed = 10.0);
                swim := make_animation("Frog-Swim",     speed = 6.0);

                charge := make_animation("Frog-Charge");
                jump := make_animation("Frog-Jump",     speed = 30.0);
                fly := make_animation("Frog-Fly");
                land := make_animation("Frog-Land",     speed = 50.0);

                animation = idle;


                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 5;
                    b.likelihood = 0.2;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Wander_Floor);
                    b.animation = walk;
                    b.idle_animation = idle;

                    b.bouncy_x = true;

                    b.minimum_duration = 8;
                    b.likelihood = 0.3;

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
                    b.likelihood = 0.1;

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

                    b.likelihood = 0.4;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = sleep;
                }

                {
                    shock_behavior = xx New(Behavior_One_Shot);
                    using shock_behavior;
                    animation = shock;
                }

                {
                    heart_behavior = xx New(Behavior_One_Shot);
                    using heart_behavior;
                    animation = heart;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP, .SLEEP,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "6 years old.");
                array_add(*facts, "has over 10,000 children!");
                array_add(*facts, "");
                array_add(*facts, "frog was the");
                array_add(*facts, "first guy I made.");

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

                idle := make_animation("Tako-Idle",     speed = 10.0);
                walk := make_animation("Tako-Walk",     speed = 10.0);
                swim := make_animation("Tako-Swim",     speed = 25.0);
                sleep := make_animation("Tako-Sleep",   speed = 10.0);
                shock := make_animation("Tako-Shock",   speed = 15.0);
                heart := make_animation("Tako-Heart",   speed = 8.0);

                animation = idle;


                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 5;
                    b.likelihood = 0.2;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Wander_Floor);
                    b.animation = walk;
                    b.idle_animation = idle;

                    b.bouncy_x = true;

                    b.minimum_duration = 15;
                    b.likelihood = 0.4;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Swim_Upward);
                    b.animation = swim;

                    b.speed = 30.0;

                    b.swimming = true;
                    b.bouncy_x = true;
                    b.bouncy_y = false;

                    b.minimum_duration = 6;
                    b.likelihood = 0.4;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = sleep;
                }

                {
                    shock_behavior = xx New(Behavior_One_Shot);
                    using shock_behavior;
                    animation = shock;
                }

                {
                    heart_behavior = xx New(Behavior_One_Shot);
                    using heart_behavior;
                    animation = heart;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

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

                array_add(*facts, "A professional chef.");
                array_add(*facts, "");
                array_add(*facts, "favorite food: souffle.");
                array_add(*facts, "least favorite: peas.");
                array_add(*facts, "(but he will eat them");
                array_add(*facts, "if they are on his plate.)");

                color = red;
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

                idle := make_animation("Clam-Idle");
                sleep := make_animation("Clam-Sleep", speed = 2.0);
                shock := make_animation("Clam-Shock", speed = 12.0);
                heart := make_animation("Clam-Heart", speed = 10.0);

                animation = idle;


                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 5;
                    b.likelihood = 1.0;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = sleep;
                }

                {
                    shock_behavior = xx New(Behavior_One_Shot);
                    using shock_behavior;
                    animation = shock;
                }

                {
                    heart_behavior = xx New(Behavior_One_Shot);
                    using heart_behavior;
                    animation = heart;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

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

                array_add(*facts, "A real homebody.");
                array_add(*facts, "only comes out sometimes.");
                array_add(*facts, "");
                array_add(*facts, "I think she is watching");
                array_add(*facts, "Gossip Girl in there.");

                color = white;
            }
        }

        jelly : *Guy = xx new_entity(.GUY);
        {
            using jelly;

            name = "jelly";

            rarity = .COMMON;

            x = 196;
            y = 16;
            width  = 12;
            height = 14;

            {
                using personality;

                idle := make_animation("Jelly-Idle",    speed = 7.0);
                walk := make_animation("Jelly-Walk",    speed = 10.0);
                swim := make_animation("Jelly-Swim",    speed = 25.0);
                sleep := make_animation("Jelly-Sleep",  speed = 10.0);
                shock := make_animation("Jelly-Shock",  speed = 20.0);
                heart := make_animation("Jelly-Heart",  speed = 10.0);

                animation = idle;


                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 5;
                    b.likelihood = 0.3;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Wander_Floor);
                    b.animation = walk;
                    b.idle_animation = idle;

                    b.bouncy_x = true;

                    b.minimum_duration = 10;
                    b.likelihood = 0.4;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Swim_Upward);
                    b.animation = swim;

                    b.speed = 30.0;

                    b.swimming = true;
                    b.bouncy_x = true;
                    b.bouncy_y = false;

                    b.minimum_duration = 20;
                    b.likelihood = 0.3;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = sleep;
                }

                {
                    shock_behavior = xx New(Behavior_One_Shot);
                    using shock_behavior;
                    animation = shock;
                }

                {
                    heart_behavior = xx New(Behavior_One_Shot);
                    using heart_behavior;
                    animation = heart;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP,
                        .NEUTRAL, .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL, .SLEEP,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "would enjoy a hug,");
                array_add(*facts, "but is extremely toxic.");

                array_add(*facts, "don't get too close!");

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

                idle := make_animation("Blowfish-Idle",     speed = 7.0);
                walk := make_animation("Blowfish-Walk",     speed = 10.0);
                bounce := make_animation("Blowfish-Bounce", speed = 10.0);
                heart := make_animation("Blowfish-Happy",   speed = 10.0);
                sleep := make_animation("Blowfish-Sleep",   speed = 10.0);
                //shock := make_animation("Blowfish-Shock");

                animation = idle;


                {
                    b := New(Behavior_Wander);
                    b.animation = walk;
                    b.idle_animation = idle;

                    b.speed = 15.0;

                    b.swimming = true;
                    b.bouncy_x = true;
                    b.bouncy_y = true;

                    b.minimum_duration = 5;
                    b.likelihood = 0.5;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Swim);
                    b.animation = walk;
                    b.down_animation = walk;

                    b.speed = 25;

                    b.swimming = true;
                    b.bouncy_x = true;
                    b.bouncy_y = true;

                    b.minimum_duration = 10;
                    b.likelihood = 0.5;

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

                    b.minimum_duration = 3;

                    shock_behavior = xx b;
                }

                {
                    b := New(Behavior_One_Shot);
                    b.animation = heart;

                    b.swimming = true;

                    heart_behavior = xx b;
                }

                {
                    b := New(Behavior_Eat);
                    b.animation = idle;

                    eat_behavior = xx b;
                }

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .NEUTRAL,
                        .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "curious, but cautious.");
                array_add(*facts, "does not like surprises.");
                array_add(*facts, "");
                array_add(*facts, "often dreams of the ocean.");

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

                idle := make_animation("Blobfish-Idle",         speed = 1.0);
                blink := make_animation("Blobfish-Blink",       speed = 10.0);
                yawn := make_animation("Blobfish-OpenMouth",    speed = 10.0);

                animation = idle;

                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 5;
                    b.likelihood = 0.9;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_One_Shot);
                    b.animation = yawn;

                    b.likelihood = 0.05;
                    b.sfx = "yawning";

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_One_Shot);
                    b.animation = blink;

                    b.likelihood = 0.05;
                    b.sfx = "SimpleBlink";

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = idle;
                }

                {
                    shock_behavior = xx New(Behavior_One_Shot);
                    using shock_behavior;
                    animation = idle;
                }

                {
                    heart_behavior = xx New(Behavior_One_Shot);
                    using heart_behavior;
                    animation = idle;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

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

                array_add(*facts, "???");

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

                idle := make_animation("Crab-Idle",     speed = 10.0);
                walk := make_animation("Crab-Walk",     speed = 10.0);
                heart := make_animation("Crab-Heart",   speed = 1.0);
                shock := make_animation("Crab-Shock",   speed = 1.0);
                sleep := make_animation("Crab-Sleep",   speed = 2.0);

                animation = idle;


                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 3;
                    b.likelihood = 0.2;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Wander_Floor);
                    b.animation = walk;
                    b.idle_animation = idle;

                    b.minimum_duration = 10;
                    b.likelihood = 0.8;

                    b.speed = 25;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = sleep;
                }

                {
                    shock_behavior = xx New(Behavior_One_Shot);
                    using shock_behavior;
                    animation = shock;
                }

                {
                    heart_behavior = xx New(Behavior_One_Shot);
                    using heart_behavior;
                    animation = heart;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, 
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "crab likes to");
                array_add(*facts, "hang out in the sand.");
                array_add(*facts, "");
                array_add(*facts, "cannot be harmed by");
                array_add(*facts, "physical means.");

                color = orange;
            }
        }

        turtle : *Guy = xx new_entity(.GUY);
        {
            using turtle;

            name = "turtle";

            rarity = .RARE;

            x = 128;
            y = 48;
            width  = 12;
            height = 12;

            directionality = .FOUR_WAY;

            {
                using personality;

                idle := make_animation("Turtle-Idle",     speed = 3.0);
                cardinal := make_animation("Turtle-Cardinal",     speed = 3.0);
                diagonal := make_animation("Turtle-Diagonal",     speed = 3.0);
                heart := make_animation("Turtle-Heart",   speed = 1.0);
                shock := make_animation("Turtle-Shock",   speed = 10.0);
                sleep := make_animation("Turtle-Sleep",   speed = 3.0);

                animation = cardinal;


                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 5;
                    b.likelihood = 0.3;

                    b.swimming = true;

                    array_add(*neutral_behaviors, xx b);
                }


                {
                    b := New(Behavior_Eight_Way);
                    b.animation = cardinal;
                    b.diagonal_animation = diagonal;

                    b.minimum_duration = 5;
                    b.likelihood = 0.7;

                    b.swimming = true;
                    b.bouncy_x = true;
                    b.bouncy_y = true;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = sleep;

                    swimming = true;
                }

                {
                    shock_behavior = xx New(Behavior_One_Shot);
                    using shock_behavior;
                    animation = shock;

                    swimming = true;
                }

                {
                    heart_behavior = xx New(Behavior_One_Shot);
                    using heart_behavior;
                    animation = heart;

                    swimming = true;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;

                    swimming = true;
                }

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP, .SLEEP,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP, .SLEEP, .SLEEP,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "I");
                array_add(*facts, "love");
                array_add(*facts, "turtles");
                array_add(*facts, "!");

                color = brown;
            }
        }

        axolotl : *Guy = xx new_entity(.GUY);
        {
            using axolotl;

            name = "axolotl";

            rarity = .RARE;

            x = 72;
            y = 16;
            width  = 12;
            height = 8;

            {
                using personality;

                idle    := make_animation("Axolotl-Idle",   speed = 4.0);
                walk    := make_animation("Axolotl-Walk",   speed = 10.0);
                flote   := make_animation("Axolotl-Float",  speed = 8.0);
                stand   := make_animation("Axolotl-Stand",  speed = 3.0);
                sit     := make_animation("Axolotl-Sit",    speed = 1.0);
                roll    := make_animation("Axolotl-Roll",   speed = 6.0);

                swim_up     := make_animation("Axolotl-Swim-Up",  speed = 7.0);
                swim_down   := make_animation("Axolotl-Swim-Down",  speed = 7.0);

                eat     := make_animation("Axolotl-Eat",    speed = 4.0);
                sleep   := make_animation("Axolotl-Sleep",  speed = 4.0);
                heart   := make_animation("Axolotl-Heart",  speed = 4.0);

                animation = idle;

                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 5;
                    b.likelihood = 0.1;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Idle);
                    b.animation = sit;

                    b.minimum_duration = 4;
                    b.likelihood = 0.3;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Idle);
                    b.animation = stand;

                    b.minimum_duration = 4;
                    b.likelihood = 0.1;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Idle);
                    b.animation = eat;

                    b.minimum_duration = 20;
                    b.likelihood = 0.1;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Wander_Floor);
                    b.animation = walk;
                    b.idle_animation = idle;

                    b.bouncy_x = true;

                    b.speed = 20;

                    b.minimum_duration = 5;
                    b.likelihood = 0.1;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Forward);
                    b.animation = roll;

                    b.speed = 10.0;

                    b.bouncy_x = true;

                    b.minimum_duration = 10;
                    b.likelihood = 0.1;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Swim);
                    b.animation = swim_up;
                    b.down_animation = swim_down;

                    b.speed = 25;

                    b.swimming = true;
                    b.bouncy_x = true;
                    b.bouncy_y = true;

                    b.minimum_duration = 20;
                    b.likelihood = 0.2;

                    array_add(*neutral_behaviors, xx b);
                }


                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = sleep;
                }

                {
                    shock_behavior = xx New(Behavior_One_Shot);
                    using shock_behavior;
                    animation = idle;
                }

                {
                    heart_behavior = xx New(Behavior_One_Shot);
                    using heart_behavior;
                    animation = heart;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .NEUTRAL, .SLEEP, .SLEEP, .SLEEP, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .SLEEP, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "like an underwater dog.");
                array_add(*facts, "(does not know any tricks)");
                array_add(*facts, "");
                array_add(*facts, "Can regenerate its limbs");
                array_add(*facts, "I think.");

                color = pink;
            }
        }

        star : *Guy = xx new_entity(.GUY);
        {
            using star;

            name = "star";

            rarity = .RARE;

            x = 96;
            y = 16;
            width  = 12;
            height = 4;

            {
                using personality;

                idle    := make_animation("Star-Idle",   speed = 4.0);
                kick    := make_animation("Star-Kick",   speed = 8.0);

                shock   := make_animation("Star-Shock",  speed = 8.0);
                yawn    := make_animation("Star-Yawn",   speed = 5.0);
                heart   := make_animation("Star-Heart",  speed = 8.0);

                animation = idle;

                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 5;
                    b.likelihood = 0.9;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    b := New(Behavior_Idle);
                    b.animation = kick;

                    b.minimum_duration = 3;
                    b.likelihood = 0.1;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = yawn;
                }

                {
                    shock_behavior = xx New(Behavior_One_Shot);
                    using shock_behavior;
                    animation = shock;
                }

                {
                    heart_behavior = xx New(Behavior_One_Shot);
                    using heart_behavior;
                    animation = heart;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .NEUTRAL, .SLEEP, .SLEEP, .SLEEP, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "The star of the show.");

                color = pink;
            }
        }

        dumbo : *Guy = xx new_entity(.GUY);
        {
            using dumbo;

            name = "dumbo";

            rarity = .RARE;

            x = 96;
            y = 80;
            width  = 8;
            height = 8;

            {
                using personality;

                idle    := make_animation("Dumbo-Idle",     speed = 4.0);

                animation = idle;

                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 5;
                    b.likelihood = 1.0;

                    b.swimming = true;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = idle;
                }

                {
                    shock_behavior = xx New(Behavior_One_Shot);
                    using shock_behavior;
                    animation = idle;
                }

                {
                    heart_behavior = xx New(Behavior_One_Shot);
                    using heart_behavior;
                    animation = idle;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .NEUTRAL, .SLEEP, .SLEEP, .SLEEP, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, ":.");

                color = yellow;
            }
        }

        angler : *Guy = xx new_entity(.GUY);
        {
            using angler;

            name = "angler";

            rarity = .RARE;

            x = 120;
            y = 72;
            width  = 14;
            height = 14;

            {
                using personality;

                idle    := make_animation("Angler-Idle",     speed = 4.0);

                animation = idle;

                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 5;
                    b.likelihood = 1.0;

                    b.swimming = true;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = idle;
                }

                {
                    shock_behavior = xx New(Behavior_One_Shot);
                    using shock_behavior;
                    animation = idle;
                }

                {
                    heart_behavior = xx New(Behavior_One_Shot);
                    using heart_behavior;
                    animation = idle;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .NEUTRAL, .SLEEP, .SLEEP, .SLEEP, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "he will eat you!");
                array_add(*facts, "but will apologize after...");

                color = blue;
            }
        }

        narwhal : *Guy = xx new_entity(.GUY);
        {
            using narwhal;

            name = "narwhal";

            rarity = .RARE;

            x = 64;
            y = 96;
            width  = 26;
            height = 12;

            {
                using personality;

                idle    := make_animation("Narwhal-Idle",     speed = 2.0);

                animation = idle;

                {
                    b := New(Behavior_Idle);
                    b.animation = idle;

                    b.minimum_duration = 5;
                    b.likelihood = 1.0;

                    b.swimming = true;

                    array_add(*neutral_behaviors, xx b);
                }

                {
                    sleep_behavior = xx New(Behavior_Sleep);
                    using sleep_behavior;
                    animation = idle;
                }

                {
                    shock_behavior = xx New(Behavior_One_Shot);
                    using shock_behavior;
                    animation = idle;
                }

                {
                    heart_behavior = xx New(Behavior_One_Shot);
                    using heart_behavior;
                    animation = idle;
                }

                {
                    eat_behavior = xx New(Behavior_Eat);
                    using eat_behavior;
                    animation = idle;
                }

                {
                    schedule.hours = Plan.[
                        .SLEEP, .SLEEP, .SLEEP, .NEUTRAL, .SLEEP, .SLEEP, .SLEEP, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL,
                        .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .NEUTRAL, .SLEEP,
                    ];
                }
            }

            {
                using biography;

                array_add(*facts, "swimming in the ocean");
                array_add(*facts, "causing a commotion");
                array_add(*facts, "cause it is so awesome");

                color = white;
            }
        }


        // Add all the guys defined here to the list of guys who can be populated.
        {
            array_add(*game.guys, frog);
            array_add(*game.guys, tako);
            array_add(*game.guys, clam);
            array_add(*game.guys, crab);
            array_add(*game.guys, jelly);
            array_add(*game.guys, blowfish);
            array_add(*game.guys, turtle);
            array_add(*game.guys, axolotl);

            /*
            // v1.1
            array_add(*game.guys, star);
            array_add(*game.guys, dumbo);
            array_add(*game.guys, narwhal);
            array_add(*game.guys, angler);
            array_add(*game.guys, blob);
            */
        }

        /*
        // Validate some stuff about these guys
        {
            for guy : game.guys {
                // Neutral behavior likelihoods must add up to 1.
                {
                    total := 0.0;
                    for behavior : guy.personality.neutral_behaviors  total += behavior.likelihood;
                    assert(total == 1.0);
                }
            }
        }
        */

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
    seed : u64 = cast(u64)t.hour - 1 + (cast(u64)t.day_of_week_starting_at_0 << 8);

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
