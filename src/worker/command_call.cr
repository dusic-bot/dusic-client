class Worker
  # Data about single command call
  struct CommandCall
    alias Context = NamedTuple(
      author_id: UInt64,
      author_roles_ids: Array(UInt64),
      server_id: UInt64,
      channel_id: UInt64,
      voice_channel_id: UInt64?)

    getter name : String
    getter arguments : Array(String)
    getter options : Hash(String, String?)
    getter author_id : UInt64
    getter author_roles_ids : Array(UInt64)
    getter server_id : UInt64
    getter channel_id : UInt64
    getter voice_channel_id : UInt64?
    getter call_time : Time

    def initialize(@name, @arguments, @options, context : Context)
      @call_time = Time.utc
      @author_id = context[:author_id]
      @author_roles_ids = context[:author_roles_ids]
      @server_id = context[:server_id]
      @channel_id = context[:channel_id]
      @voice_channel_id = context[:voice_channel_id]
    end

    def to_s(io : IO) : Nil
      io << "`" << name << "`" << arguments << options << " at " << server_id << " by " << author_id
    end
  end
end
