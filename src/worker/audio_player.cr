require "./audio_player/*"

class Worker
  # Single audio player
  class AudioPlayer
    CONNECTION_TIMEOUT        = 6.seconds
    CONNECTION_CHECK_INTERVAL = 500.milliseconds
    AUDIO_LOAD_FAILED_TIMEOUT = 5.seconds
    AUDIO_PLAY_INTERVAL       = 1.second

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

    enum AudioStopFlag
      False
      TruePreserveCurrent
      True
    end

    enum MessageType
      Loading
      FailedToLoad
      Playing
    end

    @loop_stop_flag : LoopStopFlag = LoopStopFlag::True
    @track_stop_flag : AudioStopFlag = AudioStopFlag::True
    @current_audio_frames_count : UInt64 = 0
    @last_message : NamedTuple(channel_id: UInt64, message_id: UInt64)? = nil

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
      unless disconnected?
        Log.warn { "play called for server##{@server_id}, although status is #{@status}" }
      end

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
        # TODO: check whether daily stats aren't outdated
        # TODO: check autopause
        # TODO: check time limit

        if audio = queue.shift(1).first?
          # TODO: add track to statistic
          start_audio_play(audio)
          sleep AUDIO_PLAY_INTERVAL
        else
          @loop_stop_flag = LoopStopFlag::True
        end
      end
    ensure
      @loop_stop_flag = LoopStopFlag::False
      @status = Status::Connected
      @worker.api_client.server_save(server)
      delete_last_audio_message
    end

    private def stop_play_loop : Nil
      Log.debug { "stopping play loop at server##{@server_id}" }
      @loop_stop_flag = LoopStopFlag::True
    end

    private def start_audio_play(audio : Audio) : Nil
      Log.debug { "playing #{audio} at server##{@server_id}" }

      @track_stop_flag = AudioStopFlag::False
      @status = Status::Playing
      @current_audio = audio

      begin
        case audio.status
        when Audio::Status::NotReady
          prepare_current_audio(audio)
        when Audio::Status::Loading
          await_audio(audio)
        when Audio::Status::Destroyed
          # TODO: skip audio
        end
      rescue exception
        Log.error(exception: exception) { "failed loading #{audio}" }
      end

      prepare_next_audio

      if audio.status == Audio::Status::Ready
        send_audio_message(MessageType::Playing, audio)
        sleep 5.seconds # TODO: play audio, skipping @current_audio_frames_count
      else
        send_audio_message(MessageType::FailedToLoad, audio)
        sleep AUDIO_LOAD_FAILED_TIMEOUT
      end
    rescue exception
      Log.error(exception: exception) { "failed playing #{audio} at server##{@server_id}" }
    ensure
      if @track_stop_flag == AudioStopFlag::TruePreserveCurrent
        @current_audio_frames_count = 0_u64 # TODO: actual value
      else
        @current_audio = nil
      end
      @status = Status::Connected
      @track_stop_flag = AudioStopFlag::False

      audio.destroy unless @queue.includes?(audio)
    end

    private def stop_audio_play(preserve_current : Bool = false) : Nil
      Log.debug { "stopping current track at server##{@server_id}" }

      @track_stop_flag = preserve_current ? AudioStopFlag::TruePreserveCurrent : AudioStopFlag::True
    end

    private def play_async(channel_id : UInt64) : Nil
      Dusic.spawn("ap_#{@server_id}") { play_sync(channel_id) }
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
      # TODO: await until audio is not in Audio::Status::Loading anymore
    end

    private def prepare_current_audio(audio : Audio) : Nil
      send_audio_message(MessageType::Loading, audio)
      prepare_audio(audio)
    end

    private def prepare_next_audio : Nil
      audio = queue.first?
      return if audio.nil?

      Dusic.spawn("audio_prep") { prepare_audio(audio) }
    end

    private def prepare_audio(audio : Audio) : Nil
      Log.debug { "preparing #{audio} for server##{@server_id}" }

      sleep 2.seconds # TODO: call audio prepare algorithm
    end

    def send_audio_message(type : MessageType, audio : Audio) : UInt64?
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

    def delete_last_audio_message : Nil
      if last_message = @last_message
        @worker.discord_client.delete_message(last_message[:channel_id], last_message[:message_id])
        @last_message = nil
      end
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
  end
end
