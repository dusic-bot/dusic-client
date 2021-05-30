require "./base"

class Worker
  class CommandCallExecutor
    # NOTE: Pseudo-command
    class UnavailableInDmCommand < Base
      def execute
        command_name = @command_data.not_nil![:name]
        reply(
          t("commands.#{command_name}.title"),
          t("commands.#{command_name}.errors.unavailable_in_dm"),
          "danger"
        )
      end
    end
  end
end
