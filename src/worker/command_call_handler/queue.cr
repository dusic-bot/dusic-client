class Worker
  class CommandCallHandler
    class Queue
      Log = CommandCallHandler::Log.for("queue")

      DEFAULT_SIZE   = 2
      DM_TIMEOUT     = 0.seconds
      SERVER_TIMEOUT = 1.second

      @queue : Deque(CommandCall) = Deque(CommandCall).new(DEFAULT_SIZE)
      @fiber : Fiber? = nil
      @timeout : Time::Span

      def initialize(@worker : Worker, @server_id : UInt64)
        @timeout = @server_id.zero? ? DM_TIMEOUT : SERVER_TIMEOUT
      end

      def push(command_call : CommandCall)
        @queue.push(command_call)
        execute
      end

      private def execute
        return if executing?

        @fiber = Dusic.spawn { execution_loop }
      end

      private def executing?
        fiber = @fiber
        return false if fiber.nil?

        !fiber.dead?
      end

      private def execution_loop
        Log.debug { "execution loop started" }
        while command_call = @queue.shift?
          @worker.command_call_executor.execute(command_call)
          sleep @timeout
        end
        Log.debug { "execution loop finished" }
      end
    end
  end
end
