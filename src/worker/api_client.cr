require "./api_client/*"

class Worker
  class ApiClient
    Log = Worker::Log.for("api_client")

    @is_running : Bool = false
    @http_client : HttpClient
    @websocket_client : WebsocketClient
    @servers : Hash(UInt64, Mapping::Server)

    def initialize(@worker : Worker)
      @http_client = HttpClient.new
      @websocket_client = WebsocketClient.new(@worker)
      @servers = Hash(UInt64, Mapping::Server).new { |hash, id| hash[id] = get_server(id) }
    end

    def run : Nil
      Log.info { "starting API client" }
      @is_running = true
      @websocket_client.run
      renew_servers_cache
    end

    def stop : Nil
      Log.info { "stopping API client" }
      @websocket_client.stop
      @is_running = false
    end

    def server(server_id : UInt64) : Mapping::Server
      # TODO: Outdating cache?
      @servers[server_id]
    end

    def server_save(server) : Mapping::Server
      put_server(server)
    end

    private def get_servers : Array(Mapping::Server)
      response = @http_client.get("discord_servers?shard_id=#{@worker.shard_id}&shard_num=#{@worker.shard_num}")
      Array(Mapping::Server).from_json(response)
    end

    private def get_server(server_id : UInt64) : Mapping::Server
      response = @http_client.get("discord_servers/#{server_id}")
      Mapping::Server.from_json(response)
    end

    private def put_server(server : Mapping::Server) : Mapping::Server
      response = @http_client.put("discord_servers/#{server.id}", server.to_json)
      Mapping::Server.from_json(response)
    end

    private def get_audios(manager : String, query : String, type : String = "auto") : Mapping::AudioRequest
      response = @http_client.get("audios?manager=#{manager}&type=#{type}&query=#{URI.encode_www_form(query)}")
      Mapping::AudioRequest.from_json(response)
    end

    private def get_audio(manager : String, id : String, format : String, volume : UInt8) : File
      File.tempfile("#{manager}_#{id}_#{format}_#{volume}") do |file_io|
        @http_client.get_raw("audios/#{manager}/#{id}?format=#{format}&volume=#{volume}") do |io|
          IO.copy(io, file_io)
        end
      end
    end

    private def renew_servers_cache : Nil
      get_servers.each do |server|
        @servers[server.id] = server
      end
    end
  end
end
