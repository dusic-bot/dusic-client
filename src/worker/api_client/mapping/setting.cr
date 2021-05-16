require "json"

class Worker
  class ApiClient
    module Mapping
      class Setting
        include JSON::Serializable

        property dj_role : UInt64?
        property language : String
        property autopause : Bool
        property volume : Int32
        @[JSON::Field(emit_null: true)]
        property prefix : String?
      end
    end
  end
end
