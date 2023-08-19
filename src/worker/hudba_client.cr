require "./hudba_client/*"

class Worker
  class HudbaClient
    Log = Worker::Log.for("hudba_client")

    @is_running : Bool = false
    @http_client : HttpClient

    def initialize(@worker : Worker)
      @http_client = HttpClient.new
    end

    def run : Nil
      Log.info { "starting Hudba client" }
      @is_running = true
    end

    def stop : Nil
      Log.info { "stopping Hudba client" }
      @is_running = false
    end

    def audios_request(query : String) : Mapping::AudioRequest?
      # TODO: Caching?
      get_audios(query)
    end

    def audio_file(id : String, format : String) : File?
      # TODO: Caching?
      get_audio(id, format)
    end

    private def get_audios(query : String) : Mapping::AudioRequest?
      response = @http_client.post("vk/audios/request", body: { argument: query }.to_json)
      if response.success?
        Mapping::AudioRequest.from_json(response.body)
      else
        nil
      end
    end

    private def get_audio(id : String, format : String) : File?
      success : Bool = true

      file = File.tempfile("#{id}_#{format}") do |file_io|
        @http_client.get_raw("vk/audios/#{id}/#{format}") do |response|
          success = response.success?
          IO.copy(response.body_io, file_io) if success
        end
      end

      if success
        file
      else
        file.delete
        nil
      end
    end
  end
end
