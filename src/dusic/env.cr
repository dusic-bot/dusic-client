module Dusic::Env
  extend self

  enum Environment
    Test
    Development
    Canary
    Production
  end

  @@env : Environment? = nil

  # Return environment
  def env : Environment
    @@env ||= get_env
  end

  protected def get_env : Environment
    case ENV.fetch("ENV", "development").downcase
    when "test"               then Environment::Test
    when "dev", "development" then Environment::Development
    when "staging", "canary"  then Environment::Canary
    when "production"         then Environment::Production
    else                           Environment::Development
    end
  end
end
