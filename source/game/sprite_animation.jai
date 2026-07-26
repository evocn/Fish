// Dayne
// Sprite Animation
// September 2024

Sprite_Animation :: struct {
    sheet : string;
    frame_count : int;

    speed : float = 1.0;

    // State
    frame   : int;      @NoSerialize
    t       : float;    @NoSerialize
}

reset :: (using animation : *Sprite_Animation) {
    frame = 0;
    t = 0;
}

update :: (using animation : *Sprite_Animation, dt: float) -> finished : bool {
    t += dt;
    change_time := 1.0 / speed;
    if t < change_time then return false;
    t = fmod_cycling(t, change_time);

    // Next frame
    frame = (frame + 1) % frame_count;

    return 0 == frame;
}
