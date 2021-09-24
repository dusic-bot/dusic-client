class Worker
  class DiscordClient
    # Discord voice client facade
    abstract class VoiceClient
      # Returns current frame (originally 'frame' is 20 ms of playback)
      abstract def current_frame : UInt64
      # VSU event handler
      abstract def voice_server_update(endpoint : String, token : String, session_id : String) : Nil
      # Setup WS close event listener
      abstract def on_close(&on_close : ->) : Nil
      # Play single track
      abstract def play(audio : AudioPlayer::Audio, skip_frames : UInt64 = 0_u64) : Nil
      # Stop playback
      abstract def stop : Nil
    end
  end
end
