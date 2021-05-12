require "./base"

class Worker
  class CommandCallExecutor
    class CancelCommand < Base
      def execute
        Log.debug { "Command #{self.class}" }
        # TODO
      end
    end
  end
end
