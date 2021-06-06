require "./command"

class Worker
  class CommandCallExecutor
    # NOTE: Pseudo-command
    class ErrorCommand < Command
      def execute
        prefix_local : String = begin
          prefix
        rescue exception
          Log.error(exception: exception) { "failed to fetch prefix" }
          ""
        end

        reply(
          t("commands.error.title"),
          t("commands.error.text.unknown_error", {prefix: prefix}),
          "danger"
        )
      end
    end
  end
end
