require "json"

class Worker
  class HudbaClient
    module Mapping
      class AudioRequest
        include JSON::Serializable

        getter type : String
        getter object : Audio | Array(Audio) | Playlist
      end
    end
  end
end
