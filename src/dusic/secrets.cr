require "../secrets"

module Dusic::Secrets
  extend self

  @@secrets : YAML::Any = Dusic.get_secrets

  # Return secrets from config
  def secrets : YAML::Any
    @@secrets
  end

  protected def get_secrets : YAML::Any
    environment = case Dusic.get_env
                  when Environment::Test        then "test"
                  when Environment::Development then "development"
                  when Environment::Canary      then "canary"
                  when Environment::Production  then "production"
                  else                               "development"
                  end
    ::Secrets.read_yaml(environment)
  end
end
