require "log"

require "./dusic"

class Worker
  Log = ::Log.for("worker")

  @is_running : Bool = false

  def initialize(@shard_id : Int32, @shard_num : Int32)
  end

  def run
    @is_running = true
    Log.info { "worker #{@shard_id}_#{@shard_num} running..." }

    while @is_running
      sleep 5.seconds # TODO: Do actual things lol
    end
  end

  def stop
    # TODO: Do actual things lol

    Log.info { "worker #{@shard_id}_#{@shard_num} stopping..." }
    @is_running = false
  end
end
