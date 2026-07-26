// Dayne
// Color
// August 2024

Color :: Vector4;
Hex_Color :: u32;

color_none :: Color.{};
white   :: #run color_from_hex(0xffffff);
black   :: #run color_from_hex(0x060608);
gray    :: #run color_from_hex(0x7c7c7c);

purple  :: #run color_from_hex(0x2f256b);
red     :: #run color_from_hex(0xd14444);
green   :: #run color_from_hex(0x67ab7a);
yellow  :: #run color_from_hex(0xECA72C);
orange  :: #run color_from_hex(0xFF7F50);
blue    :: #run color_from_hex(0x067ab7);
pink    :: #run color_from_hex(0xb869d3);
teal    :: #run color_from_hex(0x1cc7d4);


color_from_hex :: ($h: u32) -> Color {
    color : Color;
    color.x = ((h >> 16) & 0xff) / 255.0;
    color.y = ((h >> 8) & 0xff) / 255.0;
    color.z = ((h >> 0) & 0xff) / 255.0;
    color.w = 1.0;

    return color;
}


// Rainbow Color

rainbow_color : Color;

rainbow_color_time : float;
RAINBOW_OSCILLATION_SPEED :: 5.0;

update_rainbow_color :: (dt: float) -> Color {
    rainbow_color_time += dt * RAINBOW_OSCILLATION_SPEED;

    if rainbow_color_time >= 6.0 then rainbow_color_time = rainbow_color_time - 6.0;
    
    if rainbow_color_time > 5.0 then return yellow;
    else if rainbow_color_time > 4.0 then return pink;
    else if rainbow_color_time > 3.0 then return blue;
    else if rainbow_color_time > 2.0 then return green;
    else if rainbow_color_time > 1.0 then return red;
    return purple;
}

// Random Color
random_color :: () -> Color {
    return Color.{
        x = random_get_zero_to_one(),
        y = random_get_zero_to_one(),
        z = random_get_zero_to_one(),
        w = 1.0,
    };
}
