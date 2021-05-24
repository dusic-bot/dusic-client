require "./base"

class Worker
  class CommandCallExecutor
    # NOTE: Pseudo-command
    class UnknownCommand < Base
      def execute
        reply(
          t("commands.unknown.title"),
          t("commands.unknown.text", {name: @command_call.name}),
          "danger"
        )
      end
    end
  end
end
