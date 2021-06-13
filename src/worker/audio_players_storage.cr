class Worker
  # Handle audio players
  class AudioPlayersStorage
    Log = Worker::Log.for("audio_players_storage")

    def initialize(@worker : Worker)
      @audio_players = Hash(UInt64, AudioPlayer).new do |hash, key|
        hash[key] = AudioPlayer.new(@worker, key)
      end
    end

    def audio_player(server_id : UInt64, channel_id : UInt64? = nil) : AudioPlayer
      player = @audio_players[server_id]
      player.channel_id = channel_id unless channel_id.nil?
      player
    end

    def active_count : Int32
      @audio_players.count { |server_id, audio_player| !audio_player.disconnected? }
    end

    def stop_all : Nil
      Log.debug { "Stopping #{@audio_players.size} audio players" }
      @audio_players.each do |id, player|
        begin
          player.stop
        rescue exception
          Log.warn(exception: exception) { "Failed to gracefully stop audio player for server #{id}" }
        end
      end
    end
  end
end
