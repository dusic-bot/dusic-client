require "./dusic_client/*"

# Root namespace
module DusicClient
  VERSION = "6.0.0"

  @@env : Environment?

  def self.env : Environment
    @@env ||= case ENV.fetch("ENV", "development").downcase
    when "test" then Environment::Test
    when "dev", "development" then Environment::Development
    when "production" then Environment::Production
    else Environment::Development
    end
  end
end
