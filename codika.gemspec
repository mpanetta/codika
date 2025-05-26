require "English"
Gem::Specification.new do |gem|
  gem.name = "Codika"
  gem.version = Codika::VERSION

  gem.authors = ["Michael Panetta"]
  gem.email = "mpanetta+codika@gmail.com"
  gem.homepage = "https://github.com/mpanetta/codika"
  gem.license = "MIT"

  gem.description = "Codika is a small flexible framework for extracting and maintaining domain logic in Rails applications"
  gem.summary = "Codika is a small flexible framework for extracting and maintaining domain logic in Rails applications"
  gem.files = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.required_ruby_version = "3.4.4"

  gem.metadata["rubygems_mfa_required"] = "true"
end
