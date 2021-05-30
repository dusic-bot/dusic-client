require "./base"

class Worker
  class CommandCallExecutor
    class StopCommand < Base
      def execute
        Log.debug { "Command #{self.class}" }
        # TODO
      end
    end
  end
end
