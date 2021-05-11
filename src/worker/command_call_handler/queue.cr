class Worker
  class CommandCallHandler
    class Queue
      def initialize(@server_id : UInt64)
      end

      def push(command_call : CommandCall)
        # TODO
      end
    end
  end
end
