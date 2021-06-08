require "./audio_player/*"

class Worker
  # Single audio player
  class AudioPlayer
    alias AudioArray = Array(Audio) | Array(AssetAudio) | Array(RemoteAudio)

    getter queue : Queue

    def initialize(@worker : Worker, @server_id : UInt64)
      @queue = Queue.new(@worker, @server_id)
    end

    def play
      Log.debug { "Play" }
      # TODO
    end

    def skip
      Log.debug { "Skip" }
      # TODO
    end

    def stop
      Log.debug { "Stop" }
      # TODO
    end

    def handle_voice_server_update(token : String, endpoint : String) : Nil
      Log.debug { "VSU" }
      # TODO
    end
  end
end
