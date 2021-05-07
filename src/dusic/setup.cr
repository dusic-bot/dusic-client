require "log"
Log.setup(Dusic.env == Dusic::Environment::Production ? Log::Severity::Info : Log::Severity::Debug)

require "i18n"
I18n.load_path += ["config/locales/**/"]
I18n.init
I18n.default_locale = "ru"
