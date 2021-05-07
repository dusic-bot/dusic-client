enum Dusic::Environment
  Test
  Development
  Canary
  Production
end

module Dusic
  @@env : Environment = Dusic.get_env

  # Return environment
  def self.env : Environment
    @@env
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
end
