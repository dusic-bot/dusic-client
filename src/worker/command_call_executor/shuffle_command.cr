require "./command"

class Worker
  class CommandCallExecutor
    class ShuffleCommand < Command
      def execute
        audio_player.queue.shuffle

        reply(t("commands.shuffle.title"), t("commands.shuffle.text.queue_shuffled"), "success")
      end
    end
  end
end
