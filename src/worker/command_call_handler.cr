class Worker
  class CommandCallHandler
    Log = Worker::Log.for("command_call_handler")

    def initialize(@worker : Worker)
    end

    def handle(command_calls : Array(CommandCall)) : Nil
      Log.debug { "Handling #{command_calls.size} command calls: #{command_calls.join("; ")}" }
    end
  end
end
