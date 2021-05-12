require "./base"

class Worker
  class CommandCallExecutor
    # NOTE: Pseudo-command
    class ErrorCommand < Base
      def execute
        Log.debug { "Command #{self.class}" }
        # TODO
      end
    end
  end
end
