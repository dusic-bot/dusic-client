class Worker
  # Data about single command call
  struct CommandCall
    getter name : String
    getter arguments : Array(String)
    getter options : Hash(String, String?)
    getter server_id : UInt64
    getter channel_id : UInt64

    def initialize(@name, @arguments, @options, @server_id, @channel_id)
    end

    def to_s(io : IO) : Nil
      io << "`" << name << "`" << arguments << options
    end
  end
end
