// Dayne
// Audio
// September 2024

Audio_Context :: struct {
    sfx : Table(string, Sound_Data);
    music : Table(string, Sound_Data);

    music_stream : *Sound_Stream;
}

////////////////////////////////////////////////////////////////////////////////

play_sfx :: (name : string, perturb := false) {
    sfx := table_find_pointer(*audio_context.sfx, name);
    if !sfx {
        print("Unable to play sfx %\n", name);
        return;
    }

    stream := make_stream(sfx, .GENERAL_SFX);

    // Modify SFX properties
    {
        if perturb {
            stream.user_volume_scale = random_get_within_range(0.5, 1.4);
            stream.rate_scale        = random_get_within_range(0.7, 1.22);
        }
    }

    start_playing(stream);
}

play_music :: (name : string) {
    // Kill currently playing music
    if audio_context.music_stream {
        stop_stream_abruptly(audio_context.music_stream.entity_id);
    }

    music := table_find_pointer(*audio_context.music, name);
    if !music then {
        print("Unable to play music %\n", name);
        return;
    }

    stream := make_stream(music, .MUSIC);

    // Modify Music properties
    {
        set_repeating(stream, true);
    }

    start_playing(stream);

    // Hold onto this so you can kill the music sometimes.
    audio_context.music_stream = stream;
}

change_playing_song_volume :: (name : string) {
}
