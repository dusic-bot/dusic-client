require "./audio_player/*"

class Worker
  # Single audio player
  class AudioPlayer
    def initialize(@worker : Worker)
      # TODO
    end

    def stop
      # TODO
    end

    def handle_voice_server_update(token : String, endpoint : String) : Nil
      # TODO
    end
  end
end
