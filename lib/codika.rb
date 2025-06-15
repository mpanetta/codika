VERSION = "0.0.0".freeze

require "active_support/core_ext/hash"
require "i18n"
require "ostruct"

require "codika/actionable"
require "codika/context"
require "codika/organizable"
require "codika/serviceable"

I18n.load_path += Dir[File.expand_path("../config/locales/*.yml", __dir__)]
