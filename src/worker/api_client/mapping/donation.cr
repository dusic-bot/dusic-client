require "json"

class Worker
  class ApiClient
    module Mapping
      class Donation
        include JSON::Serializable

        getter id : Int32
        getter size : Int32
        getter server_id : UInt64?
        getter user_id : UInt64?
        @[JSON::Field(converter: Converter::DatetimeToTime)]
        getter date : Time
      end
    end
  end
end
