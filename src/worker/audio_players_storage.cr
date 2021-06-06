class Worker
  # Handle audio players
  class AudioPlayersStorage
    Log = Worker::Log.for("audio_players_storage")

    getter audio_players : Hash(UInt64, AudioPlayer)

    def initialize(@worker : Worker)
      @audio_players = Hash(UInt64, AudioPlayer).new do |hash, key|
        hash[key] = AudioPlayer.new(@worker)
      end
    end

    def audio_player(server_id : UInt64) : AudioPlayer
      @audio_players[server_id]
    end

    def stop_all : Nil
      Log.debug { "Stopping #{audio_players.size} audio players" }
      audio_players.each do |id, player|
        begin
          player.stop
        rescue exception
          Log.warn(exception: exception) { "Failed to gracefully stop audio player for server #{id}" }
        end
      end
    end

    # Pass Discord voice server update event to audio player
    def handle_voice_server_update(server_id : UInt64, token : String, endpoint : String) : Nil
      audio_player(server_id).handle_voice_server_update(token, endpoint)
    end
  end
end
