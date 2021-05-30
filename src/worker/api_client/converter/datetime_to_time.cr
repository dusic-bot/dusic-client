require "json"

class Worker
  class ApiClient
    module Converter
      module DatetimeToTime
        FORMAT = "%F %T %Z"

        def self.from_json(parser : JSON::PullParser)
          Time.parse!(parser.read_string, FORMAT)
        end

        def self.to_json(value : Time, builder : JSON::Builder)
          builder.string(value.to_s(FORMAT))
        end
      end
    end
  end
end
