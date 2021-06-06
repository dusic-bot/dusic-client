require "./command"

class Worker
  class CommandCallExecutor
    class PlayCommand < Command
      def execute
        Log.debug { "Command #{self.class}" }
        # TODO
      end
    end
  end
end
