class Worker
  class AudioPlayer
    class Queue
      def initialize(@worker : Worker, @server_id : UInt64)
        @queue = [] of Audio
      end

      def empty?
        @queue.empty?
      end

      def full?
        size >= limit
      end

      def size : UInt32
        @queue.size.to_u32
      end

      def limit : UInt32
        server.premium? ? 10_000_u32 : 2_000_u32
      end

      def unshift(audios : Array(Audio)) : Nil
        @queue.concat(audios)
        @queue.rotate!(@queue.size - audios.size)
      end

      def push(audios : Array(Audio)) : Nil
        @queue.concat(audios)
      end

      private def server : ApiClient::Mapping::Server
        @worker.api_client.server(@server_id)
      end
    end
  end
end
