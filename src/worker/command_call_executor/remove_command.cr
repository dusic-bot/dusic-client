require "./command"

class Worker
  class CommandCallExecutor
    class RemoveCommand < Command
      def execute : Nil
        if audio_player.queue.empty?
          reply(t("commands.remove.title"), t("commands.remove.text.audio_queue_is_empty"), "success")
          return
        end

        argument = @command_call.arguments.join
        initial_size = audio_player.queue.size

        begin
          remove_audios(argument)
        rescue exception
          reply(t("commands.remove.title"), t("commands.remove.errors.incorrect_arguments"), "danger")
          return
        end

        removed_count = initial_size - audio_player.queue.size
        reply(t("commands.remove.title"), t("commands.remove.text.removed_audios", count: removed_count), "success")
      end

      private def remove_audios(argument)
        if argument == "queue" || argument == "all"
          audio_player.queue.clear
        elsif argument.includes?('-')
          from_index, to_index = argument.split('-', 2).map { |i| i.to_i32 - 1 }.sort
          to_index = Math.min(audio_player.queue.size - 1, to_index)
          raise "Out of borders" if from_index < 0 || from_index >= audio_player.queue.size

          audio_player.queue.delete_at(from_index..to_index)
        else
          index = argument.to_i32 - 1
          raise "Out of borders" if index < 0 || index >= audio_player.queue.size

          audio_player.queue.delete_at(index..index)
        end
      end
    end
  end
end
