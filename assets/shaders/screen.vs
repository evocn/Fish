#version 330 core
layout (location = 0) in vec2 VertexPosition;

uniform mat4 projection;
uniform mat4 model;

uniform vec2 spritesheet_offset;
uniform vec2 relative_sheet_scale;

uniform int horizontal_flip;

out vec2 texture_coordinates;

void main()
{
    vec2 uv = VertexPosition;
    uv.y = 1.0 - uv.y;

    uv.x = (1 - horizontal_flip) * uv.x + (horizontal_flip) * (1.0 - uv.x);

    texture_coordinates = spritesheet_offset + uv * relative_sheet_scale;
    gl_Position = projection * model * vec4(VertexPosition, 0.0, 1.0);
}
