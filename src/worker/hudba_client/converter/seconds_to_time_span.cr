require "json"

class Worker
  class HudbaClient
    module Converter
      module SecondsToTimeSpan
        def self.from_json(parser : JSON::PullParser)
          Time::Span.new(seconds: parser.read_int)
        end

        def self.to_json(value : Time::Span, builder : JSON::Builder)
          builder.number(value.total_seconds.to_i)
        end
      end
    end
  end
end
