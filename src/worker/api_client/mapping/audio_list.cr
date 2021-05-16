require "json"

class Worker
  class ApiClient
    module Mapping
      class AudioList
        include JSON::Serializable

        getter title : String
        getter audios : Array(Audio)
      end
    end
  end
end
