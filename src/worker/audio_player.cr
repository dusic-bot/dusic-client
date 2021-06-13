require "./audio_player/*"

class Worker
  # Single audio player
  class AudioPlayer
    CONNECTION_TIMEOUT        = 6.seconds
    CONNECTION_CHECK_INTERVAL = 500.milliseconds
    AUDIO_LOAD_FAILED_TIMEOUT = 3.seconds
    AUDIO_PLAY_INTERVAL       = 1.second
    PLAY_STOP_AWAIT           = 5.seconds
    PLAY_STOP_CHECK_INTERVAL  = 500.milliseconds

    Log = Worker::Log.for("audio_player")

    alias AudioArray = Array(Audio) | Array(AssetAudio) | Array(RemoteAudio)

    enum Status
      Disconnected
      Connecting
      Connected
      Playing
      Disconnecting
    end

    enum LoopStopFlag
      False
      True
    end

    enum MessageType
      Loading
      FailedToLoad
      Playing
    end

    @bot_id : UInt64 = Dusic.secrets["bot_id"].as_s.to_u64
    @loop_stop_flag : LoopStopFlag = LoopStopFlag::True
    @current_audio_frames_count : UInt64 = 0
    @last_message : NamedTuple(channel_id: UInt64, message_id: UInt64)? = nil
    @play_fiber : Fiber? = nil

    getter queue : Queue
    getter status : Status
    getter current_audio : Audio?
    property channel_id : UInt64?

    {% for value in Status.constants %}
      def {{ value.downcase }}?
        status == Status::{{ value }}
      end
    {% end %}

    def initialize(@worker : Worker, @server_id : UInt64)
      @queue = Queue.new(@worker, @server_id)
      @status = Status::Disconnected
      @current_audio = nil
      @channel_id = nil
    end

    def play(channel_id : UInt64) : Nil
      return unless disconnected?

      play_async(channel_id)
    end

    def skip : Nil
      return if disconnected?

      stop_audio_play(preserve_current: false)
    end

    def stop(preserve_current : Bool = false) : Nil
      return if disconnected?

      stop_play_loop
      stop_audio_play(preserve_current: preserve_current)
      if play_fiber = @play_fiber
        finished_properly = Dusic.await(PLAY_STOP_AWAIT, PLAY_STOP_CHECK_INTERVAL) { play_fiber.dead? }
        Log.warn { "play fiber at server##{@server_id} didn't finish properly" } unless finished_properly
      end
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
      @loop_stop_flag = LoopStopFlag::False

      # Resume suspended play
      if audio = @current_audio
        start_audio_play(audio)
        @current_audio_frames_count = 0_u64
      end

      # Main loop
      while @loop_stop_flag == LoopStopFlag::False
        @worker.api_client.server_save(server) if daily_outdated?

        if autopause_enabled? && no_listeners?
          send(t("audio_player.text.autopause_warning"), "secondary")
          @loop_stop_flag = LoopStopFlag::True
          next
        end

        if time_limit_hit?
          Log.info { "playback time limit hit at server##{@server_id}" }
          send(t("audio_player.text.time_limit_warning"), "secondary")
          @loop_stop_flag = LoopStopFlag::True
          next
        end

        if audio = queue.shift(1).first?
          add_audio_to_statistic(audio)
          start_audio_play(audio)
          sleep AUDIO_PLAY_INTERVAL
        else
          @loop_stop_flag = LoopStopFlag::True
        end
      end
    ensure
      @loop_stop_flag = LoopStopFlag::False
      @status = Status::Connected
      delete_last_audio_message
      @worker.api_client.server_save(server)
      Log.debug { "play loop finished at server##{@server_id}" }
    end

    private def stop_play_loop : Nil
      Log.debug { "stopping play loop at server##{@server_id}" }
      @loop_stop_flag = LoopStopFlag::True
    end

    private def start_audio_play(audio : Audio) : Nil
      Log.debug { "playing #{audio} at server##{@server_id}" }

      @status = Status::Playing
      @current_audio = audio

      prepare_current_audio(audio)
      prepare_next_audio

      if audio.ready?
        send_audio_message(MessageType::Playing, audio)
        voice_client.try &.play(audio, skip_frames: @current_audio_frames_count)
      else
        send_audio_message(MessageType::FailedToLoad, audio)
        sleep AUDIO_LOAD_FAILED_TIMEOUT
      end
    rescue exception
      Log.error(exception: exception) { "failed playing #{audio} at server##{@server_id}" }
    ensure
      @status = Status::Connected

      audio.destroy unless @queue.includes?(audio) || @current_audio == audio
    end

    private def stop_audio_play(preserve_current : Bool = false) : Nil
      Log.debug { "stopping current track at server##{@server_id}" }

      if preserve_current
        @current_audio_frames_count = voice_client.try &.current_frame || 0_u64
      else
        @current_audio = nil
      end
      voice_client.try &.stop
    end

    private def play_async(channel_id : UInt64) : Nil
      if @play_fiber
        Log.warn { "play fiber already exists for server##{@server_id}" }
      end

      @play_fiber = Dusic.spawn("ap_#{@server_id}") do
        play_sync(channel_id)
        @play_fiber = nil
      end
    end

    private def play_sync(channel_id : UInt64) : Nil
      voice_connect(channel_id)
      start_play_loop
    rescue exception
      Log.error(exception: exception) { "failure during playback" }
    ensure
      voice_disconnect
    end

    private def await_audio(audio : Audio) : Nil
      Dusic.await(AUDIO_AWAIT_TIMEOUT, AUDIO_AWAIT_CHECK_INTERVAL) do
        audio.status != Audio::Status::Loading
      end
    end

    private def prepare_current_audio(audio : Audio) : Nil
      send_audio_message(MessageType::Loading, audio) unless audio.ready?
      prepare_audio(audio)
    end

    private def prepare_next_audio : Nil
      audio = queue.first?
      return if audio.nil?

      Dusic.spawn("audio_prep") { prepare_audio(audio) }
    end

    private def prepare_audio(audio : Audio) : Nil
      Log.debug { "preparing #{audio} for server##{@server_id}" }

      @worker.audio_preparer.prepare(audio)
    end

    private def send_audio_message(type : MessageType, audio : Audio) : UInt64?
      t_options = {
        artist:   audio.artist,
        title:    audio.title,
        duration: Dusic.format_seconds(audio.duration),
      }

      key =
        case type
        when MessageType::Loading      then "loading"
        when MessageType::FailedToLoad then "failed_to_load"
        when MessageType::Playing      then "playing"
        else                                "playing"
        end

      delete_last_audio_message
      channel_id = @channel_id
      message_id = send(t("audio_player.text.#{key}", t_options), "primary")
      if channel_id && message_id
        @last_message = {channel_id: channel_id, message_id: message_id}
      end
      message_id
    end

    private def delete_last_audio_message : Nil
      if last_message = @last_message
        @worker.discord_client.delete_message(last_message[:channel_id], last_message[:message_id])
        @last_message = nil
      end
    end

    private def add_audio_to_statistic(audio : Audio) : Nil
      local_server = server

      local_server.today_statistic.tracks_length += audio.duration.to_i
      local_server.today_statistic.tracks_amount += 1
      local_server.statistic.tracks_length += audio.duration.to_i
      local_server.statistic.tracks_amount += 1
    end

    private def daily_outdated? : Bool
      Time.utc - server.today_statistic.date >= 1.day
    end

    private def autopause_enabled? : Bool
      return true unless premium?

      server.setting.autopause
    end

    private def no_listeners? : Bool
      bot_voice_channel_id = @worker.discord_client.user_voice_channel_id(@server_id, @bot_id)
      return true if bot_voice_channel_id.nil?

      ids = @worker.discord_client.voice_channel_users(@server_id, bot_voice_channel_id)
      ids.delete(@bot_id)

      ids.size.zero?
    end

    private def time_limit_hit? : Bool
      return false if premium?

      server.today_statistic.tracks_length > 30.minutes.to_i
    end

    private def send(text : String, color_key : String? = nil) : UInt64?
      if channel_id = @channel_id
        title = Dusic.t("audio_player.title") { server.setting.language }
        color = color_key ? Dusic.color(color_key) : nil
        @worker.discord_client.send_embed(channel_id, title, text, color: color)
      end
    end

    private def t(*args, **opts) : String
      Dusic.t(*args, **opts) { server.setting.language }
    end

    private def server : ApiClient::Mapping::Server
      @worker.api_client.server(@server_id)
    end

    private def premium? : Bool
      server.premium?
    end

    private def voice_client : DiscordClient::VoiceClient?
      client = @worker.discord_client.voice_client(@server_id)
      if client.nil?
        Log.warn { "voice client required for server##{@server_id}, but is nil" }
      end
      client
    end
  end
end
