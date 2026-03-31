# frozen_string_literal: true

require_relative "lib/mihari/rails/version"

Gem::Specification.new do |spec|
  spec.name          = "mihari-rails"
  spec.version       = Mihari::Rails::VERSION
  spec.authors       = ["Mihari"]
  spec.email         = ["support@mihari.io"]

  spec.summary       = "Rails integration for the Mihari log transport library"
  spec.description   = "Rack middleware, ActiveSupport log subscribers, and Rails " \
                        "auto-configuration for shipping structured logs to Mihari."
  spec.homepage      = "https://github.com/mihari-io/mihari-rails"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib}/**/*", "LICENSE", "README.md"]
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "mihari-ruby", "~> 0.1"
  spec.add_dependency "railties",    ">= 6.1", "< 8.0"

  spec.add_development_dependency "bundler",   "~> 2.0"
  spec.add_development_dependency "rake",      "~> 13.0"
  spec.add_development_dependency "rspec",     "~> 3.0"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "rack-test", "~> 2.0"
  spec.add_development_dependency "rubocop",   "~> 1.0"
  spec.add_development_dependency "webmock",   "~> 3.0"
end
