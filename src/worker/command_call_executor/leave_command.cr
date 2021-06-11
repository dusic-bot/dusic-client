require "./command"

class Worker
  class CommandCallExecutor
    class LeaveCommand < Command
      def execute : Nil
        audio_player.stop(preserve_current: true)

        reply(t("commands.leave.title"), t("commands.leave.text.playback_suspended"), "success")
      end
    end
  end
end
