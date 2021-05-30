require "json"

class Worker
  class ApiClient
    module Converter
      module DateToTime
        def self.from_json(parser : JSON::PullParser)
          Time::Format::ISO_8601_DATE.parse(parser.read_string)
        end

        def self.to_json(value : Time, builder : JSON::Builder)
          builder.string(Time::Format::ISO_8601_DATE.format(value))
        end
      end
    end
  end
end
