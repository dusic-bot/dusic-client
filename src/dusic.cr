require "./secrets"

# Shared features
module Dusic
  VERSION = "6.0.0"

  enum Environment
    Test
    Development
    Canary
    Production
  end

  @@env : Environment?
  @@secrets : YAML::Any?

  def self.env : Environment
    @@env ||= case ENV.fetch("ENV", "development").downcase
              when "test"               then Environment::Test
              when "dev", "development" then Environment::Development
              when "staging", "canary"  then Environment::Canary
              when "production"         then Environment::Production
              else                           Environment::Development
              end
  end

  def self.secrets : YAML::Any
    return @@secrets if @@secrets

    environment = case Dusic.env
                  when Environment::Test        then "test"
                  when Environment::Development then "development"
                  when Environment::Canary      then "canary"
                  when Environment::Production  then "production"
                  end
    @@secrets = Secrets.read_yaml(environment)
  end
end
