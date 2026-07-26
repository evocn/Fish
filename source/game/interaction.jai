// Dayne
// Player Interaction
// September 2024

Cursor_State :: enum {
    NEUTRAL;
    PET;
    SNAP;
    SLEEP;
}

simulate_interactions :: (game: *Game) {
    using game.player.input;

    if mouse_active {
        hover_guy : *Guy;
        for game.entities {
            if it.kind != .GUY then continue;
            guy := cast(*Guy)it;
            if within(mouse_position, guy.collider) {
                hover_guy = guy;
                // @TODO: Resolve z collisions properly.
            }
        }

        if hover_guy && !game.focused_guy {
            if left_mouse.just_pressed {
                if #complete game.cursor.state == {
                    case .NEUTRAL; {
                        game.focused_guy = hover_guy;
                    }
                    case .PET; {
                        play_sfx("smooch");
                        change_to_behavior(hover_guy, hover_guy.personality.heart_behavior);
                    }
                    case .SNAP; {
                        play_sfx("thunder");
                        change_to_behavior(hover_guy, hover_guy.personality.shock_behavior);
                    }
                    case .SLEEP; {
                        play_sfx("sleep");
                        change_to_behavior(hover_guy, hover_guy.personality.sleep_behavior);
                    }
                }
            }
        }
        else {
            if left_mouse.just_pressed {
                game.focused_guy = null;
            }
        }
    }

    if north.just_pressed {
        play_sfx("thunder");
        shock_everyone(game);
    }
}

shock_everyone :: (game : *Game) {
    for game.entities {
        if it.kind != .GUY then continue;
        guy := cast(*Guy)it;
        change_to_behavior(guy, guy.personality.shock_behavior);
    }
}

sleep_everyone :: (game : *Game) {
    for game.entities {
        if it.kind != .GUY then continue;
        guy := cast(*Guy)it;
        change_to_behavior(guy, guy.personality.sleep_behavior);
    }
}

heart_everyone :: (game : *Game) {
    for game.entities {
        if it.kind != .GUY then continue;
        guy := cast(*Guy)it;
        change_to_behavior(guy, guy.personality.heart_behavior);
    }
}
