require "./audio_player/*"

class Worker
  # Single audio player
  class AudioPlayer
    CONNECTION_TIMEOUT        = 6.seconds
    CONNECTION_CHECK_INTERVAL = 500.milliseconds

    Log = Worker::Log.for("audio_player")

    alias AudioArray = Array(Audio) | Array(AssetAudio) | Array(RemoteAudio)

    enum Status
      Disconnected
      Connecting
      Connected
      Playing
      Disconnecting
    end

    getter queue : Queue
    getter status : Status
    getter current_audio : Audio?

    {% for value in Status.constants %}
      def {{ value.downcase }}?
        status == Status::{{ value }}
      end
    {% end %}

    def initialize(@worker : Worker, @server_id : UInt64)
      @queue = Queue.new(@worker, @server_id)
      @current_audio = nil
      @status = Status::Disconnected
    end

    def play(channel_id : UInt64) : Nil
      voice_connect(channel_id)
      start_play_loop
    rescue exception
      Log.error(exception: exception) { "failure during playback" }
    ensure
      voice_disconnect
    end

    def skip : Nil
      return if disconnected?

      stop_current_audio(preserve_current: false)
    end

    def stop(preserve_current : Bool = false) : Nil
      return if disconnected?

      stop_play_loop
      stop_current_audio(preserve_current: preserve_current)
    end

    private def voice_client : DiscordClient::VoiceClient?
      @worker.discord_client.voice_client(@server_id)
    end

    private def voice_connect(channel_id : UInt64) : Nil
      unless disconnected?
        Log.warn { "voice_connect called for server##{@server_id}, although audio player status is #{status}" }
        return
      end

      Log.debug { "connecting to voice channel at server##{@server_id}" }
      @status = Status::Connecting

      @worker.discord_client.voice_state_update(@server_id, channel_id)
      is_connected = Dusic.await(CONNECTION_TIMEOUT, CONNECTION_CHECK_INTERVAL) { voice_client }

      if is_connected
        @status = Status::Connected
      else
        @status = Status::Disconnected
        raise "Voice connection failure"
      end
    end

    private def voice_disconnect : Nil
      Log.debug { "disconnecting from server##{@server_id}" }
      @status = Status::Disconnecting
      @worker.discord_client.voice_state_update(@server_id, nil)
    rescue exception
      Log.error(exception: exception) { "failed to disconnect from voice channel at server##{@server_id}" }
    ensure
      @status = Status::Disconnected
    end

    private def start_play_loop : Nil
      Log.debug { "starting play loop at server##{@server_id}" }
      # TODO: play tracks from queue
    end

    private def stop_play_loop : Nil
      Log.debug { "stopping play loop at server##{@server_id}" }
      # TODO: stop playing tracks from queue
    end

    private def stop_current_audio(preserve_current : Bool = false) : Nil
      Log.debug { "stopping current track at server##{@server_id}" }
      # TODO: stop currently playing track
    end
  end
end
