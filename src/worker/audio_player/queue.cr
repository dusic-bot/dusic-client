class Worker
  class AudioPlayer
    PREMIUM_MAXIMUM_SIZE = 10_000
    MAXIMUM_SIZE         =  2_000

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

      def size : Int32
        @queue.size
      end

      def limit : Int32
        server.premium? ? PREMIUM_MAXIMUM_SIZE : MAXIMUM_SIZE
      end

      def unshift(audios : Array(Audio)) : Nil
        @queue.concat(audios)
        @queue.rotate!(@queue.size - audios.size)
      end

      def push(audios : Array(Audio)) : Nil
        @queue.concat(audios)
      end

      def [](start : Int, count : Int) : Array(Audio)
        @queue[start, count]
      end

      def clear : Nil
        @queue.clear
      end

      def delete_at(range : Range) : Nil
        @queue.delete_at(range)
      end

      def shuffle : Nil
        @queue.shuffle!
      end

      private def server : ApiClient::Mapping::Server
        @worker.api_client.server(@server_id)
      end
    end
  end
end
