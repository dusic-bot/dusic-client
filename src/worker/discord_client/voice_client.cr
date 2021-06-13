require "discordcr"

class Worker
  class DiscordClient
    # Discord voice client facade
    class VoiceClient
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
          Log.warn { "attempting to play #{audio} with status #{audio.status} at server##{@server_id}" }
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
        sleep 5.seconds # TODO: play DCA parser
      end
    end
  end
end
