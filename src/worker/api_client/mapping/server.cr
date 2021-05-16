require "json"

class Worker
  class ApiClient
    module Mapping
      class Server
        include JSON::Serializable

        getter id : UInt64
        getter setting : Setting
        getter statistic : Statistic
        getter today_statistic : DailyStatistic
        property last_donation : Donation?
      end
    end
  end
end
