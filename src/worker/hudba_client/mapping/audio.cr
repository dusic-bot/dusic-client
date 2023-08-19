require "json"

class Worker
  class ApiClient
    module Mapping
      class Audio
        include JSON::Serializable

        getter id : String
        getter artist : String
        getter title : String
        @[JSON::Field(converter: Worker::ApiClient::Converter::SecondsToTimeSpan)]
        getter duration : Time::Span
        getter cover_url : String?
        getter is_claimed : Bool
        getter decoded_url : String?
      end
    end
  end
end
