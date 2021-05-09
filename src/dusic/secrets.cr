require "../secrets"

module Dusic::Secrets
  extend self

  @@secrets : YAML::Any? = nil

  # Return secrets from config
  def secrets : YAML::Any
    @@secrets ||= get_secrets
  end

  protected def get_secrets : YAML::Any
    environment = case Dusic.env
                  when Environment::Test        then "test"
                  when Environment::Development then "development"
                  when Environment::Canary      then "canary"
                  when Environment::Production  then "production"
                  else                               "development"
                  end
    ::Secrets.read_yaml(environment)
  end
end
