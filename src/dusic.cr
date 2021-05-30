# Setup shards
require "log"
log_severity = if Dusic.env == Dusic::Environment::Production
                 Log::Severity::Info
               else
                 Log::Severity::Debug
               end
log_backend = if Dusic.env == Dusic::Environment::Test
                Log::IOBackend.new(File.new("./log/#{Dusic.env_s}.log", "w"), dispatcher: :sync)
              else
                Log::IOBackend.new
              end
Log.setup(log_severity, log_backend)

require "i18n"
I18n.load_path += ["config/locales/**/"]
I18n.init
I18n.default_locale = "ru"

require "./dusic/*"

# Dusic module itself
module Dusic
  VERSION = "6.0.0"

  extend self
  include Dusic::Env
  include Dusic::Secrets
  include Dusic::AlphabetEncoding
  include Dusic::Misc
end
