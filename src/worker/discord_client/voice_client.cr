require "discordcr"

class Worker
  class DiscordClient
    # Discord voice client facade
    class VoiceClient
      # NOTE: Discord voice client must be running and ready
      def initialize(@worker : Worker, @server_id : UInt64, @client : Discord::VoiceClient)
      end
    end
  end
end
