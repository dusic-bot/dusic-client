class Worker
  class AudioPlayer
    abstract class Audio
      enum Status
        NotReady  # Audio should be prepared
        Loading   # Audio being prepared, try later
        Ready     # Can be opened right now
        Destroyed # Do not attempt opening
      end

      getter artist : String
      getter title : String
      getter duration : Time::Span

      def initialize(@artist, @title, @duration)
      end

      def initialize(@artist, @title, duration : UInt32)
        @duration = Time::Span.new(seconds: duration)
      end

      def to_s(io : IO) : Nil
        unless artist.empty?
          io << "**" << artist << "** - "
        end

        io << "**" << title << "**"

        unless duration.zero?
          io << " `" << duration << "`"
        end
      end

      abstract def status : Status
      abstract def open(&block : IO -> Nil) : Nil
      abstract def destroy : Nil
    end
  end
end
