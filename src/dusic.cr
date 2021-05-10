# Setup shards
require "log"
Log.setup(Dusic.env == Dusic::Environment::Production ? Log::Severity::Info : Log::Severity::Debug)

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
