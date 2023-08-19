require "json"

class Worker
  class HudbaClient
    module Mapping
      class Audio
        include JSON::Serializable

        getter id : String
        getter artist : String
        getter title : String
        @[JSON::Field(converter: Worker::HudbaClient::Converter::SecondsToTimeSpan)]
        getter duration : Time::Span
        getter cover_url : String?
        getter is_claimed : Bool
        getter decoded_url : String?
      end
    end
  end
end
