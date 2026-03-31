# frozen_string_literal: true

require "mihari/rails/configuration"
require "mihari/rails/middleware"
require "mihari/rails/log_subscriber"
require "mihari/rails/tagged_logging"

module Mihari
  module Rails
    class Railtie < ::Rails::Railtie
      config.mihari = ActiveSupport::OrderedOptions.new

      initializer "mihari.configure" do |app|
        configuration = Mihari::Rails::Configuration.new

        config.mihari.each_pair do |key, value|
          if configuration.respond_to?(:"#{key}=")
            configuration.public_send(:"#{key}=", value)
          end
        end

        Mihari::Rails.configuration = configuration

        if configuration.valid?
          Mihari::Rails.setup_transport!(configuration)
        else
          ::Rails.logger.warn(
            "[Mihari] No token configured. Set config.mihari.token or MIHARI_TOKEN env var."
          )
        end
      end

      initializer "mihari.middleware", after: "mihari.configure" do |app|
        if Mihari::Rails.configuration&.auto_attach_middleware
          app.middleware.insert_before(::Rails::Rack::Logger, Mihari::Rails::Middleware)
        end
      end

      initializer "mihari.log_subscriber", after: "mihari.configure" do
        config = Mihari::Rails.configuration

        if config&.log_action_controller
          Mihari::Rails::LogSubscriber.attach_to(:action_controller)
        end

        if config&.log_active_record
          Mihari::Rails::LogSubscriber.attach_to(:active_record)
        end
      end

      initializer "mihari.tagged_logging", after: "mihari.configure" do
        if Mihari::Rails.configured?
          Mihari::Rails::TaggedLogging.install(::Rails.logger)
        end
      end

      config.after_initialize do
        if Mihari::Rails.configured?
          ::Rails.logger.info("[Mihari] Initialized for #{Mihari::Rails.configuration.resolved_app_name} (#{Mihari::Rails.configuration.resolved_environment})")
        end
      end

      at_exit do
        Mihari::Rails.shutdown!
      end
    end
  end
end
