require "./dusic"

require "./worker/*"

class Worker
  Log = ::Log.for("worker")

  @is_running : Bool = false

  @default_prefix : String = Dusic.secrets["default_prefix"].as_s
  @log_channel_id : UInt64 = Dusic.secrets["log_channel_id"].as_s.to_u64
  @bot_owner_id : UInt64 = Dusic.secrets["bot_owner_id"].as_s.to_u64

  def initialize(@shard_id : Int32, @shard_num : Int32)
    @discord_client = DiscordClient.new(shard_id, shard_num)
  end

  def run
    @is_running = true
    Log.info { "worker #{@shard_id}_#{@shard_num} running..." }

    @discord_client.run
  end

  def stop
    @discord_client.stop

    Log.info { "worker #{@shard_id}_#{@shard_num} stopping..." }
    @is_running = false
  end
end
