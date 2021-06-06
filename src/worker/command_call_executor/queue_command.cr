require "./command"

class Worker
  class CommandCallExecutor
    class QueueCommand < Command
      DISPLAYED_COUNT = 10

      def execute
        if audio_player.queue.empty?
          reply(t("commands.queue.title"), t("commands.queue.text.audio_queue_is_empty"), "success")
          return
        end

        from_index : Int32 = begin
          argument = @command_call.arguments.join
          provided_index = argument.empty? ? 0 : argument.to_i32 - 1
          if provided_index < 0
            provided_index += audio_player.queue.size
          end
          provided_index
        rescue exception
          0
        end

        audios : Array(AudioPlayer::Audio) = begin
          audio_player.queue[from_index, DISPLAYED_COUNT]
        rescue
          [] of AudioPlayer::Audio
        end

        if audios.empty?
          reply(t("commands.queue.title"), t("commands.queue.errors.could_not_load_audios"), "danger")
          return
        end

        body = String::Builder.new(t("commands.queue.text.tracks_in_queue", count: audio_player.queue.size.to_i32))
        body << ":\n"
        audios.each_with_index do |audio, index|
          body << t("commands.queue.text.track_list_line", {position: index + 1 + from_index, track: audio}) << "\n"
        end

        reply(t("commands.queue.title"), body.to_s, "success")
      end
    end
  end
end
