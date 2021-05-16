require "json"

class Worker
  class ApiClient
    module Mapping
      class DailyStatistic
        include JSON::Serializable

        property tracks_length : Int32
        property tracks_amount : Int32
        @[JSON::Field(converter: Converter::DateToTime)]
        property date : Time
      end
    end
  end
end
