require "./api_client/*"

class Worker
  class ApiClient
    Log = Worker::Log.for("api_client")

    @is_running : Bool = false

    def initialize(@worker : Worker)
    end

    def run : Nil
      Log.info { "starting API client" }
      @is_running = true
      # TODO
    end

    def stop : Nil
      Log.info { "stopping API client" }
      # TODO
      @is_running = false
    end
  end
end
