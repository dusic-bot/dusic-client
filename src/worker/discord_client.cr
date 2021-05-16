require "discordcr"

class Worker
  # Discord facade
  class DiscordClient
    alias EmbedFieldData = NamedTuple(title: String, inline: Bool, description: String)

    Log = Worker::Log.for("discord_client")

    INTENTS = Discord::Gateway::Intents::Guilds | Discord::Gateway::Intents::GuildVoiceStates |
              Discord::Gateway::Intents::GuildMessages | Discord::Gateway::Intents::DirectMessages
    STATUS_UPDATE_INTERVAL = 15.minutes

    @is_running : Bool = false

    @bot_id : UInt64 = Dusic.secrets["bot_id"].as_s.to_u64
    @bot_token : String = Dusic.secrets["bot_token"].as_s
    @default_prefix : String = Dusic.secrets["default_prefix"].as_s
    @log_channel_id : UInt64 = Dusic.secrets["log_channel_id"].as_s.to_u64

    def initialize(@worker : Worker, @shard_id : Int32, @shard_num : Int32)
      @client = Discord::Client.new(
        token: "Bot #{@bot_token}",
        shard: {shard_id: @shard_id, num_shards: @shard_num},
        client_id: @bot_id,
        intents: INTENTS
      )
      @client.cache = Discord::Cache.new(@client)

      @client.on_ready { |payload| ready_handler(payload) }
      @client.on_guild_create { |payload| guild_create_handler(payload) }
      @client.on_message_create { |message| message_create_handler(message) }
      @client.on_voice_server_update { |payload| voice_server_update_handler(payload) }
    end

    def run : Nil
      Log.info { "starting Discord client" }
      @is_running = true
      log("Starting at version: `#{Dusic::VERSION}`")
      @client.run
    end

    def stop : Nil
      Log.info { "stopping Discord client" }
      @client.stop
      @is_running = false
    end

    def log(message : String) : Nil
      @client.create_message(@log_channel_id, "`Shard##{@shard_id + 1}/#{@shard_num}`:\n#{message}")
    rescue
      Log.error { "failed to log message '#{message}' to Discord" }
    end

    def send_embed(
      channel_id : UInt64,
      title : String,
      description : String,
      footer_text : String? = nil,
      color : UInt32? = nil,
      fields : Array(EmbedFieldData) = Array(EmbedFieldData).new
    ) : UInt64?
      embed_fields = fields.map { |t| Discord::EmbedField.new(t[:title], t[:description], t[:inline]) }

      embed = Discord::Embed.new(
        title: title,
        type: "rich",
        description: description,
        colour: color,
        footer: footer_text ? Discord::EmbedFooter.new(footer_text) : nil,
        fields: embed_fields.empty? ? nil : embed_fields
      )

      @client.create_message(channel_id, "", embed)
    rescue exception : Discord::CodeException
      Log.error(exception: exception) { "Can not send message into channel##{channel_id}" }
    end

    private def ready_handler(payload : Discord::Gateway::ReadyPayload) : Nil
      Log.info { "Ready event" }

      Dusic.spawn do
        while @is_running
          update_status
          sleep STATUS_UPDATE_INTERVAL
        end
      end
    end

    private def guild_create_handler(payload : Discord::Gateway::GuildCreatePayload) : Nil
      Log.info { "New server" }
    end

    private def message_create_handler(message : Discord::Message) : Nil
      return if @client.session.nil?  # Ignore messages until discord client prepared
      return if message.author.bot    # Ignore bots
      return if message.author.system # Ignore system messages

      server_id : UInt64 = message.guild_id.try &.to_u64 || 0_u64
      channel_id : UInt64 = message.channel_id.to_u64
      command_calls = @worker.message_handler.handle(message.content, server_id, channel_id)
      @worker.command_call_handler.handle(command_calls) unless command_calls.empty?
    end

    private def voice_server_update_handler(payload : Discord::Gateway::VoiceServerUpdatePayload) : Nil
      Log.debug { "Voice server update" }
    end

    private def update_status : Nil
      Log.info { "updating Discord status" }
      @client.status_update(
        "online",
        Discord::GamePlaying.new(
          I18n.translate("status", {
            prefix:   @default_prefix,
            version:  Dusic::VERSION,
            shard_id: @shard_id,
          }),
          Discord::GamePlaying::Type::Listening
        )
      )
    rescue exception
      Log.error { "Failed to update Discord status: #{exception.message}" }
    end
  end
end
