require "./command"

class Worker
  class CommandCallExecutor
    class SkipCommand < Command
      def execute
        Log.debug { "Command #{self.class}" }
        # TODO
      end
    end
  end
end
