// Dayne
// Personality
// September 2024

// A Personality is a collection of Behaviors.
// It describes the possible actions for a fish to take in neutral,
// as well as how likely the fish is to start or get bored of actions.

Personality :: struct {
    current_whim : *Behavior;

    neutral_behaviors : [..] *Behavior;

    sleep_behavior : *Behavior;
    shock_behavior : *Behavior;
    heart_behavior : *Behavior;
    eat_behavior   : *Behavior;

    schedule : Schedule;
}

update :: (using personality: *Personality, guy: *Guy, dt: float) {
    if !current_whim {
        next_whim := whats_next(guy);
        change_to_behavior(guy, next_whim);
    }

    // Update the current whim
    update(current_whim, guy, dt);

    // Potentially get bored
    whim_has_duration := current_whim.minimum_duration != 0;
    whim_is_done := current_whim.time > current_whim.minimum_duration;
    if whim_has_duration && whim_is_done {
        current_whim.done = true;
    }

    // Change behaviors
    if current_whim.done {
        next_whim := whats_next(guy);
        change_to_behavior(guy, next_whim);
    }
}

change_to_behavior :: (guy: *Guy, next: *Behavior) {
    guy.personality.current_whim = next;
    guy.velocity = .{};
    start(next);
}

// Performs a more advanced, tweakable query which accomodates:
// - Plans from the Schedule
// - Neutral Behaviors
// - Eventually, circumstances, events, locations, interactions, etc.
whats_next :: (guy: *Guy) -> behavior: *Behavior {
    using guy.personality;

    if #complete get_current_plan(schedule) == {
        case .NEUTRAL;  return random_choice(neutral_behaviors);
        case .SLEEP;    return sleep_behavior;
        case .EAT;      return eat_behavior;
    }
}
