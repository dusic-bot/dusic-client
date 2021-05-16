require "json"

class Worker
  class ApiClient
    module Mapping
      class Audio
        include JSON::Serializable

        getter artist : String
        getter title : String
        @[JSON::Field(converter: Converter::SecondsToTimeSpan)]
        getter duration : Time::Span
        getter manager : String?
        getter id : String?
      end
    end
  end
end
