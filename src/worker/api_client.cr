require "./api_client/*"

class Worker
  class ApiClient
    Log = Worker::Log.for("api_client")

    @is_running : Bool = false
    @http_client : HttpClient
    @websocket_client : WebsocketClient
    @servers : Hash(UInt64, Mapping::Server)

    def initialize(@worker : Worker)
      @servers = Hash(UInt64, Mapping::Server).new { |hash, id| hash[id] = get_server(id) }
      @http_client = HttpClient.new
      @websocket_client = WebsocketClient.new(@worker)

      @websocket_client.on("Api::V2::ShardsChannel") do |message|
        handle_shards_message(message)
      end
      @websocket_client.on("Api::V2::DonationsChannel") do |message|
        donation = Mapping::Donation.from_json(message.to_json)
        handle_new_donation(donation)
      end
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

    private def publish_stats : Nil
      count = @worker.discord_client.servers_count
      cached = @servers.size
      active = 0 # TODO: Count of active audio connections
      data = {
        action: "connection_data",
        servers_count: count,
        cached_servers_count: cached,
        active_servers_count: active
      }.to_json

      @websocket_client.message("Api::V2::ShardsChannel", data)
    end

    private def handle_shards_message(message : Hash(String, JSON::Any)) : Nil
      case message["action"].as_s
      when "update_data"
        publish_stats
      when "restart"
        # TODO: Restart shard
      when "stop"
        Process.signal(Signal::INT, Process.pid)
      end
    end

    private def handle_new_donation(donation : Mapping::Donation) : Nil
      Log.info { "New donation registered" }
      server_id = donation.server_id
      return if server_id.nil?

      server = server(server_id)
      last_donation = server.last_donation
      return if last_donation && last_donation.date > donation.date

      server.last_donation = donation

      @worker.discord_client.log("Registered donation##{donation.id}")

      user_id = donation.user_id
      server_name = @worker.discord_client.server_name(server_id)
      if user_id && server_name
        text = I18n.translate("message.donation", {server_name: server_name}, server.setting.language)
        @worker.discord_client.send_dm(user_id, text)
      end
    rescue exception
      Log.error(exception: exception) { "failed to handle new donation" }
    end
  end
end
