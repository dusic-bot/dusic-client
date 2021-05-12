require "./base"

class Worker
  class CommandCallExecutor
    # NOTE: Pseudo-command
    class UnknownCommand < Base
      def execute
        Log.debug { "Command #{self.class}" }
        # TODO
      end
    end
  end
end
