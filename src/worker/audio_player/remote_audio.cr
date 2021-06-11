require "./audio"

class Worker
  class AudioPlayer
    class RemoteAudio < Audio
      getter manager : String
      getter id : String
      getter file : File?
      getter status : Status

      def initialize(@manager, @id, *args)
        @status = Status::NotReady
        super(*args)
      end

      def file=(new_file : File) : File
        @prepare_status = Status::Ready
        @file = new_file
      end

      def open(&block : IO -> Nil) : Nil
        begin
          io = File.open(file.not_nil!.path)
          yield(io)
        rescue exception
          Log.error(exception: exception) { "Failed to open remote audio `#{manager}##{id}`" }
        ensure
          io.try &.close
        end
      end

      def destroy : Nil
        if current_file = @file
          is_tempfile = current_file.path.starts_with?(Dir.tempdir)
          current_file.delete if is_tempfile
        end

        @file = nil
        @prepare_status = Status::Destroyed
      end
    end
  end
end
