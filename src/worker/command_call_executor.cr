require "./command_call_executor/*"

class Worker
  # Handle command calls
  class CommandCallExecutor
    Log = Worker::Log.for("command_call_executor")

    def initialize(@worker : Worker)
    end

    def execute(command_call : CommandCall) : Nil
      Log.debug { "Executing #{command_call}" }

      # TODO: execute command call
    end
  end
end
