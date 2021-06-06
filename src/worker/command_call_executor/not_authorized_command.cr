require "./command"

class Worker
  class CommandCallExecutor
    # NOTE: Pseudo-command
    class NotAuthorizedCommand < Command
      def execute
        command_name = @command_data.not_nil![:name]
        reply(
          t("commands.#{command_name}.title"),
          t("commands.#{command_name}.errors.not_authorized"),
          "danger"
        )
      end
    end
  end
end
