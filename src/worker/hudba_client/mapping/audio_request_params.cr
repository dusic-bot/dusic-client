require "json"

class Worker
  class ApiClient
    module Mapping
      class AudioRequestParams
        include JSON::Serializable

        getter argument : String
      end
    end
  end
end
