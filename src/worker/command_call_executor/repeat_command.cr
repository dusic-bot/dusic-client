require "./command"

class Worker
  class CommandCallExecutor
    class RepeatCommand < Command
      def execute
        Log.debug { "Command #{self.class}" }
        # TODO
      end
    end
  end
end
