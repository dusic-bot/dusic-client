require "./dusic"

require "./worker/*"

# Main app object. Also stores subsystems references
class Worker
  Log = ::Log.for("worker")

  SUBSYSTEMS = [
    "api_client",
    "discord_client",
    "message_handler",
    "command_call_handler",
    "command_call_executor",
    "audio_players_storage",
    "audio_selections_storage",
  ]

  @is_running : Bool = false

  @bot_owner_id : UInt64 = Dusic.secrets["bot_owner_id"].as_s.to_u64

  {% for subsystem in SUBSYSTEMS %}
    @{{subsystem.id}} : {{subsystem.camelcase.id}}? = nil
  {% end %}

  getter shard_id : Int32
  getter shard_num : Int32

  def initialize(@shard_id : Int32, @shard_num : Int32)
    {% for subsystem in SUBSYSTEMS %}
      @{{subsystem.id}} = {{subsystem.camelcase.id}}.new(self)
    {% end %}
  end

  def run : Nil
    Log.info { "starting worker #{@shard_id}_#{@shard_num}" }
    @is_running = true
    api_client.run
    discord_client.run
  end

  def stop : Nil
    Log.info { "stopping worker #{@shard_id}_#{@shard_num}" }
    discord_client.stop
    api_client.stop
    @is_running = false
  end

  {% for subsystem in SUBSYSTEMS %}
    def {{subsystem.id}} : {{subsystem.camelcase.id}}
      @{{subsystem.id}}.not_nil!
    end
  {% end %}
end
