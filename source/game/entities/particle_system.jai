// Dayne
// Particle System
// September 2024

Particle_System :: struct {
    using entity: Entity;
    kind = .PARTICLE_SYSTEM;

    // Properties
    one_shot : bool; // Whether or not particles respawn when their lifetime ends.
    lifetime_min : float;
    lifetime_max : float;

    initial_velocity_min : Vector2;
    initial_velocity_max : Vector2;

    initial_acceleration_min : Vector2;
    initial_acceleration_max : Vector2;


    // State
    particles : [100] Particle; @NoSerialize

    using rendering_details : struct {
        vao, vbo : GLuint;
        vbo_data : [..] float;
    } @NoSerialize
}

initialize_particle :: (using particle: *Particle, particle_system: *Particle_System) {
    t = 0;
    color = random_choice(Color.[white, blue, blue, blue, blue, green]);
    position = .{random(0, PIXEL_WIDTH), random(0, PIXEL_HEIGHT)};
    velocity = random(particle_system.initial_velocity_min, particle_system.initial_velocity_max);
    acceleration = random(particle_system.initial_acceleration_min, particle_system.initial_acceleration_max);
    lifetime = random(particle_system.lifetime_min, particle_system.lifetime_max);
}

initialize :: (using particle_system: *Particle_System) {
    one_shot = false;
    lifetime_min = 1.0;
    lifetime_max = 10.0;
    initial_velocity_min = .{0, 10};
    initial_velocity_max = .{0, 30};
    initial_acceleration_min = .{0, 0};
    initial_acceleration_max = .{0, -0.1};

    for * particle: particles {
        initialize_particle(particle, particle_system);
    }

    // Rendering Details
    {
        glGenVertexArrays(1, *vao);
        glGenBuffers(1, *vbo);

        glBindVertexArray(vao);
        defer glBindVertexArray(0);

        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        defer glBindBuffer(GL_ARRAY_BUFFER, 0);

        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, cast(*void)0);
        glEnableVertexAttribArray(0);

        array_resize(*vbo_data, particles.count * 2);
    }
}

update :: (using particle_system: *Particle_System, dt: float) {
    for * particle: particles {
        update(particle, dt);

        if !one_shot {
            if particle.t > particle.lifetime {
                initialize_particle(particle, particle_system);
            }
        }

        screen_pixel := world_space_to_screen_pixel(xx particle.x, xx particle.y);
        vbo_data[it_index * 2 + 0] = (cast(float)screen_pixel.x / PIXEL_WIDTH);
        vbo_data[it_index * 2 + 1] = (cast(float)screen_pixel.y / PIXEL_HEIGHT);
    }

    {
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        defer glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBufferData(
            GL_ARRAY_BUFFER,
            vbo_data.count * size_of(float),
            *vbo_data[0],
            GL_DYNAMIC_DRAW,
        );
    }
}

draw :: (using particle_system: Particle_System) {
    scale := screen_pixel_zoom();
    glPointSize(xx scale);

    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);

    shader := use_basic_shader();

    model := Matrix4_Identity;
    set_mat4(shader, "model", model);

    //set_vec4(shader, "color", white);
    //glDrawArrays(GL_POINTS, 0, xx vbo_data.count);

    for particle, index: particles {
        set_vec4(shader, "color", particle.color);
        glDrawArrays(GL_POINTS, xx (index * 2), 2);
    }
}

////////////////////////////////////////////////////////////////////////////////

Particle :: struct {
    // Properties
    color : Color;

    // State
    using position : Vector2;
    velocity : Vector2;
    acceleration : Vector2;
    lifetime : float;

    t : float;
}

update :: (using particle : *Particle, dt: float) {
    position += velocity * dt;
    velocity += acceleration * dt;

    t += dt;
}
