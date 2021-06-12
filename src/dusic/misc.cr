module Dusic::Misc
  extend self

  # Loops and calls provided block. Stops when timeout is hit (result will be `false`) or block
  # returns truthy value (result will be `true`)
  def await(timeout : Time::Span = 10.seconds, interval : Time::Span = 250.milliseconds, &block) : Bool
    time_waited = Time::Span.zero
    while time_waited < timeout
      sleep interval
      time_waited += interval
      return true if yield
    end
    false
  end

  # Wrapper around default `spawn` method
  # TODO: Currently it seems to have no use. Consider deleting
  def spawn(name : String? = nil, same_thread : Bool = false, &block)
    ::spawn(name: name, same_thread: same_thread, &block)
  end

  # Format time span in format of HH:MM:SS
  def format_seconds(ts : Time::Span) : String
    is_negative = ts < 0.seconds
    ts = ts.abs
    hours = ts.total_hours.to_i.to_s.rjust(2, '0')
    minutes = ts.minutes.to_s.rjust(2, '0')
    seconds = ts.seconds.to_s.rjust(2, '0')
    "#{is_negative ? "-" : ""}#{hours}:#{minutes}:#{seconds}"
  end

  def format_seconds(seconds : Int32) : String
    format_seconds(seconds.seconds)
  end

  # Return milliseconds since moment
  def ms_since(time : Time) : Float64
    (Time.utc - time).total_milliseconds
  end

  # Return named color UInt32 which can be accepted by Discord
  def color(key : String) : UInt32?
    I18n.translate("color.#{key}").to_u32
  rescue ArgumentError
    nil
  end

  # Wrapper over I18n.translate
  def t(
    key : String,
    options : Hash | NamedTuple? = nil,
    force_locale = nil,
    count = nil,
    default = nil,
    iter = nil,
    &block : (-> String)
  ) : String
    locale : String = if force_locale
      force_locale
    else
      block.call
    end

    I18n.translate(key, options, locale, count, default, iter)
  end

  def t(*args, **opts) : String
    t(*args, **opts) { I18n.default_locale }
  end
end
