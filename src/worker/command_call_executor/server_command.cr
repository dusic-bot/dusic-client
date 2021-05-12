require "./base"

class Worker
  class CommandCallExecutor
    class ServerCommand < Base
      def execute
        Log.debug { "Command #{self.class}" }
        # TODO
      end
    end
  end
end
