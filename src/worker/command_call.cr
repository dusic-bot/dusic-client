class Worker
  # Data about single command call
  struct CommandCall
    alias Context = NamedTuple(author_id: UInt64, server_id: UInt64, channel_id: UInt64)

    getter name : String
    getter arguments : Array(String)
    getter options : Hash(String, String?)
    getter author_id : UInt64
    getter server_id : UInt64
    getter channel_id : UInt64
    getter call_time : Time

    def initialize(@name, @arguments, @options, context : Context)
      @call_time = Time.utc
      @author_id = context[:author_id]
      @server_id = context[:server_id]
      @channel_id = context[:channel_id]
    end

    def to_s(io : IO) : Nil
      io << "`" << name << "`" << arguments << options
    end
  end
end
