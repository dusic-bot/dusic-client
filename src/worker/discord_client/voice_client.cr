require "discordcr"

class Worker
  class DiscordClient
    # Discord voice client facade
    class VoiceClient
      CONNECTION_TIMEOUT        = 4.seconds
      CONNECTION_CHECK_INTERVAL = 200.milliseconds
      IDEAL_INTERVAL            = 20.milliseconds

      Log = Worker::Log.for("discord_voice_client")

      enum ClientState
        Open
        Ready
        Closed
      end

      @stop_flag : Bool = false
      @client_state : ClientState
      @client : Discord::VoiceClient
      @on_close : (->)? = nil

      getter current_frame : UInt64

      def initialize(@server_id : UInt64, @bot_id : UInt64, endpoint : String, token : String, session_id : String)
        Log.debug { "creating new voice client for server##{@server_id}" }
        @current_frame = 0_u64
        @client_state = ClientState::Open
        @client = Discord::VoiceClient.new(endpoint, token, session_id, @server_id, @bot_id)
        @client.on_ready do
          @client_state = ClientState::Ready
        end
        spawn do
          @client.run
          @client_state = ClientState::Closed
          Log.debug { "voice connection closed at server##{@server_id}" }
          @on_close.try &.call
        end
        Dusic.await(CONNECTION_TIMEOUT, CONNECTION_CHECK_INTERVAL) { @client_state == ClientState::Ready }
      end

      def voice_server_update(endpoint : String, token : String, session_id : String) : Nil
        Log.debug { "updating voice client for server##{@server_id}" }
        new_client = Discord::VoiceClient.new(endpoint, token, session_id, @server_id, @bot_id)
        new_client_state = ClientState::Open
        new_client.on_ready do
          @client = new_client
          @client_state = ClientState::Ready
          send_speaking
        end
        spawn do
          new_client.run
          @client_state = ClientState::Closed
          Log.debug { "updated voice connection closed at server##{@server_id}" }
          @on_close.try &.call
        end
      end

      def on_close(&@on_close : ->)
      end

      def play(audio : AudioPlayer::Audio, skip_frames : UInt64 = 0_u64) : Nil
        @current_frame = 0_u64
        @stop_flag = false

        Log.info { "playing #{audio} (skip: #{skip_frames}) at server##{@server_id}" }

        unless audio.ready?
          Log.warn { "attempted to play #{audio} with status #{audio.status} at server##{@server_id}" }
          return
        end

        audio.open { |io| play_dca(io, skip_frames: skip_frames) }
      rescue exception
        Log.error(exception: exception) { "error was raised while playing #{audio}" }
      ensure
        @current_frame = 0_u64
        @stop_flag = false
      end

      def stop : Nil
        Log.info { "stopping playback at server##{@server_id}" }
        @stop_flag = true
      end

      private def play_dca(io : IO, skip_frames : UInt64 = 0_u64) : Nil
        parser = Discord::DCAParser.new(io)
        play_parser(parser, skip_frames: skip_frames)
      end

      private def play_parser(parser : Discord::DCAParser, skip_frames : UInt64 = 0_u64) : Nil
        skip_frames.times do
          parser.next_frame(reuse_buffer: true)
          @current_frame += 1_u64
        end

        send_speaking

        total_send_time = Time::Span.zero
        start_time = Time.utc
        start_frames_count = @current_frame

        while !@stop_flag
          send_time = Time.measure do
            if frame = parser.next_frame(reuse_buffer: true)
              @current_frame += 1_u64
              @client.play_opus(frame)
            else
              @stop_flag = true
            end
          end
          total_send_time += send_time

          frames_passed = @current_frame - start_frames_count
          time_passed = Time.utc - start_time
          sleep_time : Time::Span = (IDEAL_INTERVAL * frames_passed - time_passed) - send_time
          sleep({sleep_time, Time::Span.zero}.max)
        end

        total_play_time = Time.utc - start_time

        Log.info do
          <<-TEXT
          playback finished:
          Frames count: #{@current_frame}.
          Send time: #{total_send_time}.
          Average time per frame-send: #{total_send_time / @current_frame}.
          Total playtime: #{total_play_time}.
          Average time per frame-play: #{total_play_time / @current_frame}
          TEXT
        end
      end

      private def send_speaking : Nil
        @client.send_speaking(true)
      end
    end
  end
end
