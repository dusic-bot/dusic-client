require "./dusic"

require "./worker/*"

class Worker
  Log = ::Log.for("worker")

  @is_running : Bool = false

  @default_prefix : String = Dusic.secrets["default_prefix"].as_s
  @bot_owner_id : UInt64 = Dusic.secrets["bot_owner_id"].as_s.to_u64

  def initialize(@shard_id : Int32, @shard_num : Int32)
    @discord_client = DiscordClient.new(shard_id, shard_num)
  end

  def run : Nil
    Log.info { "starting worker #{@shard_id}_#{@shard_num}" }
    @is_running = true
    @discord_client.run
  end

  def stop : Nil
    Log.info { "stopping worker #{@shard_id}_#{@shard_num}" }
    @discord_client.stop
    @is_running = false
  end
end
