require "./base"

class Worker
  class CommandCallExecutor
    class AboutCommand < Base
      def execute
        Log.debug { "Command #{self.class}" }
        # TODO
      end
    end
  end
end
