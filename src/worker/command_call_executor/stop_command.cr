require "./command"

class Worker
  class CommandCallExecutor
    class StopCommand < Command
      def execute : Nil
        audio_player.stop
        audio_player.queue.clear

        reply(t("commands.stop.title"), t("commands.stop.text.playback_fully_stopped"), "success")
      end
    end
  end
end
