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

  def self.env
    @@env
  end

  def self.secrets
    @@secrets
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
