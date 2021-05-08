require "discordcr"

class Worker
  class DiscordClient
    INTENTS = Discord::Gateway::Intents::Guilds | Discord::Gateway::Intents::GuildVoiceStates |
              Discord::Gateway::Intents::GuildMessages | Discord::Gateway::Intents::DirectMessages

    @bot_id : UInt64 = Dusic.secrets["bot_id"].as_s.to_u64
    @bot_token : String = Dusic.secrets["bot_token"].as_s

    def initialize(@shard_id : Int32, @shard_num : Int32)
      @client = Discord::Client.new(
        token: "Bot #{@bot_token}",
        shard: {shard_id: @shard_id, num_shards: @shard_num},
        client_id: @bot_id,
        intents: INTENTS
      )
      @client.cache = Discord::Cache.new(@client)
    end

    def run
      @client.run
    end

    def stop
      @client.stop
    end
  end
end
