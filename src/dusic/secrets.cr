require "../secrets"

module Dusic::Secrets
  extend self

  @@secrets : YAML::Any? = nil

  # Return secrets from config
  def secrets : YAML::Any
    @@secrets ||= get_secrets
  end

  protected def get_secrets : YAML::Any
    ::Secrets.read_yaml(env_s)
  end
end
