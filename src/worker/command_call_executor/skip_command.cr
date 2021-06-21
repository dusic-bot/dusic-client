require "./command"

class Worker
  class CommandCallExecutor
    class SkipCommand < Command
      def execute : Nil
        initial_size = audio_player.queue.size
        is_currently_playing = !audio_player.current_audio.nil?

        if initial_size.zero? && !is_currently_playing
          reply(t("commands.skip.title"), t("commands.skip.text.nothing_is_playing"), "success")
          return
        end

        begin
          argument = @command_call.arguments.empty? ? 1 : @command_call.arguments.join.to_i32
          raise "Out of borders" if argument <= 0

          audio_player.queue.shift(argument - 1)
          audio_player.skip
        rescue
          reply(t("commands.skip.title"), t("commands.skip.errors.incorrect_arguments"), "danger")
          return
        end

        skipped_count = initial_size - audio_player.queue.size
        skipped_count += is_currently_playing ? 1 : 0

        reply(t("commands.skip.title"), t("commands.skip.text.tracks_skipped", count: skipped_count), "success")
      end
    end
  end
end
