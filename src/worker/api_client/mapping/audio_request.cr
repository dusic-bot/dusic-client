require "json"

class Worker
  class ApiClient
    module Mapping
      class AudioRequest
        include JSON::Serializable

        @[JSON::Field(key: "request_type")]
        getter type : String

        getter response : Array(Audio | AudioList)
      end
    end
  end
end
