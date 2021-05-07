require "./dusic"

class Worker
  Log = ::Log.for("worker")

  @is_running : Bool = false
  @bot_id : UInt64 = Dusic.secrets["bot_id"].as_s.to_u64
  @default_prefix : String = Dusic.secrets["default_prefix"].as_s
  @log_channel_id : UInt64 = Dusic.secrets["log_channel_id"].as_s.to_u64
  @bot_owner_id : UInt64 = Dusic.secrets["bot_owner_id"].as_s.to_u64

  def initialize(@shard_id : Int32, @shard_num : Int32)
  end

  def run
    @is_running = true
    Log.info { "worker #{@shard_id}_#{@shard_num} running..." }

    while @is_running
      Log.debug { "Tick" }
      sleep 5.seconds # TODO: Do actual things lol
    end
  end

  def stop
    # TODO: Do actual things lol

    Log.info { "worker #{@shard_id}_#{@shard_num} stopping..." }
    @is_running = false
  end
end
