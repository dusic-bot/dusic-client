require "./audio_player/*"

class Worker
  # Single audio player
  class AudioPlayer
    alias AudioArray = Array(Audio) | Array(AssetAudio) | Array(RemoteAudio)

    getter queue : Queue
    getter current_audio : Audio?

    def initialize(@worker : Worker, @server_id : UInt64)
      @queue = Queue.new(@worker, @server_id)
      @current_audio = nil
    end

    def play : Nil
      Log.debug { "Play" }
      # TODO: start playing
    end

    def skip : Nil
      Log.debug { "Skip" }
      # TODO: skip current track
    end

    def stop(preserve_current : Bool = false) : Nil
      Log.debug { "Stop" }
      # TODO: skip current track unless `preserve_current`; stop playback
    end

    def handle_voice_server_update(token : String, endpoint : String) : Nil
      Log.debug { "VSU" }
      # TODO: update voice server
    end
  end
end
