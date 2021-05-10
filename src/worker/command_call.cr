class Worker
  # Data about single command call
  struct CommandCall
    getter name : String
    getter arguments : Array(String)
    getter options : Hash(String, String?)

    def initialize(@name, @arguments, @options)
    end
  end
end
