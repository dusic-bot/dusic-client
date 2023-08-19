require "json"

class Worker
  class ApiClient
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
