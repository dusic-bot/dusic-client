require "discordcr"

class Worker
  class DiscordClient
    # Discord voice client facade
    class VoiceClient
      IDEAL_INTERVAL = 20.milliseconds

      Log = Worker::Log.for("discord_voice_client")

      @stop_flag : Bool = false

      getter current_frame : UInt64

      # NOTE: Discord voice client must be running and ready
      def initialize(@worker : Worker, @server_id : UInt64, @client : Discord::VoiceClient)
        @current_frame = 0_u64
      end

      def play(audio : AudioPlayer::Audio, skip_frames : UInt64 = 0_u64) : Nil
        @current_frame = 0_u64
        @stop_flag = false

        Log.debug { "playing #{audio} (skip: #{skip_frames}) at server##{@server_id}" }

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
        Log.debug { "stopping playback at server##{@server_id}" }
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

        @client.send_speaking(true)

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

        Log.debug do
          <<-TEXT
          Finished playing.
          Frames count: #{@current_frame}.
          Send time: #{total_send_time}.
          Average time per frame-send: #{total_send_time / @current_frame}.
          Total playtime: #{total_play_time}.
          Average time per frame-play: #{total_play_time / @current_frame}
          TEXT
        end
      end
    end
  end
end
