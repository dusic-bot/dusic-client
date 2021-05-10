require "./dusic"

require "./worker/*"

# Main app object. Also stores subsystems references
class Worker
  Log = ::Log.for("worker")

  @is_running : Bool = false

  @bot_owner_id : UInt64 = Dusic.secrets["bot_owner_id"].as_s.to_u64

  @discord_client : DiscordClient? = nil
  @message_handler : MessageHandler? = nil

  def initialize(@shard_id : Int32, @shard_num : Int32)
    @discord_client = DiscordClient.new(self, shard_id, shard_num)
    @message_handler = MessageHandler.new(self)
  end

  def run : Nil
    Log.info { "starting worker #{@shard_id}_#{@shard_num}" }
    @is_running = true
    discord_client.run
  end

  def stop : Nil
    Log.info { "stopping worker #{@shard_id}_#{@shard_num}" }
    discord_client.stop
    @is_running = false
  end

  def discord_client : DiscordClient
    @discord_client.not_nil!
  end

  def message_handler : MessageHandler
    @message_handler.not_nil!
  end
end
