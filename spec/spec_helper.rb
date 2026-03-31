# frozen_string_literal: true

require "rack/test"
require "webmock/rspec"
require "action_dispatch"
require "active_support"
require "rails"

# Minimal Rails app for testing
module TestApp
  class Application < ::Rails::Application
    config.eager_load = false
    config.logger = Logger.new(File::NULL)
    config.secret_key_base = "test_secret_key_base_for_mihari_rails_specs"
  end
end

require "mihari-rails"

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before(:each) do
    Mihari::Rails.reset!
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
