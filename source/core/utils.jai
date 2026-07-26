// Dayne
// Utils
// August 2024

// inarguable.
time :: () -> Calendar_Time {
    apollo_time := current_time_consensus();
    time := to_calendar(apollo_time, Time_Zone.LOCAL);
    return time;
}

Pair :: struct {
    x: int;
    y: int;
}

to_pair :: (vec: Vector2) -> Pair {
    return .{xx vec.x, xx vec.y};
}
operator + :: (a: Pair, b: Pair) -> Pair { return .{a.x + b.x, a.y + b.y};  }
operator - :: (a: Pair, b: Pair) -> Pair { return .{a.x - b.x, a.y - b.y};  }
operator * :: (f: int, a: Pair)  -> Pair { return .{a.x * f,   a.y * f};    }
operator - :: (p: Pair) -> Pair { return .{-p.x, -p.x}; }

////////////////////////////////////////////////////////////////////////////////

get_random_direction_vector_on_unit_circle :: () -> Vector2 {
    angle := random_get_zero_to_one() * (2 * PI) - PI;
    
    result : Vector2;
    result.x = cos(angle);
    result.y = sin(angle);

    return result;
}

get_random_upward_direction_vectory_on_unit_circle :: () -> Vector2 {
    result : Vector2;
    while result.y <= 0 {
        result = get_random_direction_vector_on_unit_circle();
    }

    return result;
}

////////////////////////////////////////////////////////////////////////////////

// Rounds a float to the nearest int.
round :: (f: float) -> int {
    if f > 0 {
        if f - cast(int)f > 0.5 then return cast(int)f + 1;
        else return cast(int)f;
    }
    else {
        if f + cast(int)f < -0.5 then return cast(int)f - 1;
        else return cast(int)f;
    }
}

////////////////////////////////////////////////////////////////////////////////

coin_flip :: inline () -> bool {
    if random() > 0.5 then return true; else return false;
}

// [0, 1]
random :: inline () -> float {
    return random_get_zero_to_one();
}

// [0, max]
random :: inline (max: float) -> float {
    return random_get_zero_to_one() * max;
}

// [min, max]
random :: inline (min: float, max: float) -> float {
    return random_get_within_range(min, max);
}

random :: inline (min: Vector2, max: Vector2) -> Vector2 {
    return .{
        random_get_within_range(min.x, max.x),
        random_get_within_range(min.y, max.y),
    };
}

random_choice :: inline (choices: [] $T) -> T {
    min := 0.0;
    max := cast(float)(choices.count);
    index := cast(int)random_get_within_range(min, max);
    return choices[index];
}

random_choice :: inline (choices: [] $T, seed: *Random_State) -> T {
    min := 0.0;
    max := cast(float)(choices.count);
    index := cast(int)random_get_within_range(seed, min, max);
    return choices[index];
}
