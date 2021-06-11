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

        # NOTE: it is really debatable where to place this method, but I haven't found better place
        def premium? : Bool
          if donation = @last_donation
            Time.utc <= donation.date + 31.day
          else
            false
          end
        end
      end
    end
  end
end
