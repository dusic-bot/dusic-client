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

    def server_save(server : Mapping::Server) : Mapping::Server
      new_server = put_server(server)
      @servers[new_server.id] = new_server
    end

    def server_save(server_id : UInt64) : Mapping::Server
      server = @servers[server_id]
      server_save(server)
    end

    def vk_audios(query : String) : Mapping::AudioRequest
      # TODO: Caching?
      get_audios("vk", query, "auto")
    end

    def audio(manager : String, id : String, format : String) : File?
      # TODO: Caching?
      get_audio(manager, id, format)
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

    private def get_audio(manager : String, id : String, format : String) : File?
      success : Bool = true

      file = File.tempfile("#{manager}_#{id}_#{format}") do |file_io|
        @http_client.get_raw("audios/#{manager}/#{id}?format=#{format}") do |response|
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

    private def renew_servers_cache : Nil
      get_servers.each do |server|
        @servers[server.id] = server
      end
    end

    private def publish_stats : Nil
      count = @worker.discord_client.servers_count
      cached = @servers.size
      active = @worker.audio_players_storage.active_count
      data = {
        action:               "connection_data",
        servers_count:        count,
        cached_servers_count: cached,
        active_servers_count: active,
      }.to_json

      @websocket_client.message("Api::V2::ShardsChannel", data)
    end

    private def handle_shards_message(message : Hash(String, JSON::Any)) : Nil
      case message["action"].as_s
      when "update_data"
        publish_stats
      when "restart"
        # TODO: Restart shard
      when "command_call"
        handle_command_call(message["payload"].as_h)
      when "stop"
        Process.signal(Signal::INT, Process.pid)
      end
    end

    private def handle_command_call(payload : Hash(String, JSON::Any)) : Nil
      name = payload["name"].as_s
      arguments = payload["arguments"].as_a.map &.as_s
      options = payload["options"].as_h.keys.to_h { |k| {k, nil.as(String?)} }

      server_id = payload["server_id"].as_s.try &.to_u64
      channel_id = payload["channel_id"].as_s.try &.to_u64
      author_id = payload["author_id"].as_s.try &.to_u64
      author_roles_ids : Array(UInt64) = payload["author_roles_ids"].as_a.map &.as_s.to_u64

      voice_channel_id : UInt64? = @worker.discord_client.user_voice_channel_id(server_id, author_id)

      context = {
        author_id:        author_id,
        author_roles_ids: author_roles_ids,
        server_id:        server_id || 0_u64,
        channel_id:       channel_id,
        voice_channel_id: voice_channel_id,
      }

      command_call = CommandCall.new(name, arguments, options, context)
      @worker.command_call_handler.handle([command_call])
    end

    private def handle_new_donation(donation : Mapping::Donation) : Nil
      Log.info { "new donation registered" }
      server_id = donation.server_id
      return if server_id.nil?

      server = server(server_id)
      last_donation = server.last_donation
      return if last_donation && last_donation.date > donation.date

      server.last_donation = donation

      user_id = donation.user_id
      server_name : String? = begin
        @worker.discord_client.server_name(server_id)
      rescue
        nil
      end

      if user_id && server_name
        @worker.discord_client.log("Registered donation##{donation.id}")

        text = I18n.translate("message.donation", {server_name: server_name}, server.setting.language)
        @worker.discord_client.send_dm(user_id, text)
      end
    rescue exception
      Log.error(exception: exception) { "failed to handle new donation" }
    end
  end
end
