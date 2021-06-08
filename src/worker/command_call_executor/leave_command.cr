require "./command"

class Worker
  class CommandCallExecutor
    class LeaveCommand < Command
      def execute : Nil
        Log.debug { "Command #{self.class}" }
        # TODO
      end
    end
  end
end
