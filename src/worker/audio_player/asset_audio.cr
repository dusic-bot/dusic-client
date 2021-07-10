require "./audio"

class Worker
  class AudioPlayer
    class AssetAudio < Audio
      getter asset_name : String

      def initialize(@asset_name, *args)
        super(*args)
      end

      def status : Status
        Status::Ready
      end

      def open(&block : IO -> Nil) : Nil
        begin
          file = File.open("./assets/dca/#{asset_name}.dca", "rb")
          yield(file)
        rescue exception
          Log.error(exception: exception) { "failed to open asset `#{asset_name}`" }
        ensure
          file.try &.close
        end
      end

      def destroy : Nil
      end
    end
  end
end
