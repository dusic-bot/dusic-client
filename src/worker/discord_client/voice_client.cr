class Worker
  class DiscordClient
    # Discord voice client facade
    abstract class VoiceClient
      abstract def current_frame : UInt64
      abstract def voice_server_update(endpoint : String, token : String, session_id : String) : Nil
      abstract def on_close(&on_close : ->) : Nil
      abstract def play(audio : AudioPlayer::Audio, skip_frames : UInt64 = 0_u64) : Nil
      abstract def stop : Nil
    end
  end
end
