require "json"

class Worker
  class ApiClient
    module Mapping
      class Statistic
        include JSON::Serializable

        property tracks_length : Int32
        property tracks_amount : Int32
      end
    end
  end
end
