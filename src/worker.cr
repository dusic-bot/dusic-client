require "./dusic"

require "./worker/*"

# Main app object. Also stores subsystems references
class Worker
  Log = ::Log.for("worker")

  @is_running : Bool = false

  @bot_owner_id : UInt64 = Dusic.secrets["bot_owner_id"].as_s.to_u64

  @discord_client : DiscordClient? = nil
  @message_handler : MessageHandler? = nil
  @command_call_handler : CommandCallHandler? = nil
  @command_call_executor : CommandCallExecutor? = nil

  def initialize(@shard_id : Int32, @shard_num : Int32)
    @discord_client = DiscordClient.new(self, shard_id, shard_num)
    @message_handler = MessageHandler.new(self)
    @command_call_handler = CommandCallHandler.new(self)
    @command_call_executor = CommandCallExecutor.new(self)
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

  def command_call_handler : CommandCallHandler
    @command_call_handler.not_nil!
  end

  def command_call_executor : CommandCallExecutor
    @command_call_executor.not_nil!
  end
end
