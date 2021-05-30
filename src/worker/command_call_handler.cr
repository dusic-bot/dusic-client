require "./command_call_handler/*"

class Worker
  # Handle command calls
  class CommandCallHandler
    Log = Worker::Log.for("command_call_handler")

    def initialize(@worker : Worker)
      @queues = Hash(UInt64, Queue).new do |hash, key|
        hash[key] = Queue.new(@worker, key)
      end
    end

    def handle(command_calls : Array(CommandCall)) : Nil
      Log.debug { "Handling #{command_calls.size} command calls: #{command_calls.join("; ")}" }

      command_calls.each do |command_call|
        @queues[command_call.server_id].push(command_call)
      end
    end
  end
end
