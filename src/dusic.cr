require "log"
require "i18n"

require "./secrets"

# Log setup
Log.setup(Dusic.env == Dusic::Environment::Production ? Log::Severity::Info : Log::Severity::Debug)

# I18n setup
I18n.load_path += ["config/locales/**/"]
I18n.init
I18n.default_locale = "ru"

# Shared features
module Dusic
  VERSION = "6.0.0"

  enum Environment
    Test
    Development
    Canary
    Production
  end

  @@env : Environment = Dusic.get_env
  @@secrets : YAML::Any = Dusic.get_secrets

  # Return environment
  def self.env : Environment
    @@env
  end

  # Return secrets from config
  def self.secrets : YAML::Any
    @@secrets
  end

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

  protected def self.get_env : Environment
    case ENV.fetch("ENV", "development").downcase
    when "test"               then Environment::Test
    when "dev", "development" then Environment::Development
    when "staging", "canary"  then Environment::Canary
    when "production"         then Environment::Production
    else                           Environment::Development
    end
  end

  protected def self.get_secrets : YAML::Any
    environment = case Dusic.get_env
                  when Environment::Test        then "test"
                  when Environment::Development then "development"
                  when Environment::Canary      then "canary"
                  when Environment::Production  then "production"
                  else                               "development"
                  end
    Secrets.read_yaml(environment)
  end
end
