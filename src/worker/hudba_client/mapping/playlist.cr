require "json"

class Worker
  class HudbaClient
    module Mapping
      class Playlist
        include JSON::Serializable

        getter title : String
        getter subtitle : String
        getter cover_url : String?
        getter audios : Array(Audio)
      end
    end
  end
end
