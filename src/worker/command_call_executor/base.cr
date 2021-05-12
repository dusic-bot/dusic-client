class Worker
  class CommandCallExecutor
    abstract class Base
      def initialize(@worker : Worker, @command_call : CommandCall)
      end

      abstract def execute
    end
  end
end
