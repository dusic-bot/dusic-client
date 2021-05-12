require "./base"

class Worker
  class CommandCallExecutor
    class DonateCommand < Base
      def execute
        Log.debug { "Command #{self.class}" }
        # TODO
      end
    end
  end
end
