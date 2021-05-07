require "./dusic/setup"

require "./dusic/environment"
require "./dusic/secrets"

module Dusic
  VERSION = "6.0.0"

  # Loops and calls provided block. Stops when timeout is hit (result will be `false`) or block
  # returns truthy value (result will be `true`)
  def self.await(timeout : Time::Span = 10.seconds, interval : Time::Span = 250.milliseconds, &block) : Bool
    time_waited = Time::Span.zero
    while time_waited < timeout
      sleep interval
      time_waited += interval
      return true if yield
    end
    false
  end

  # Wrapper around default `spawn` method
  # NOTE: Currently it seems to have no use consider deleting
  def self.spawn(name : String? = nil, same_thread : Bool = false, &block)
    ::spawn(name: name, same_thread: same_thread, &block)
  end
end
