# frozen_string_literal: true

require "mihari/rails/version"

module Mihari
  module Rails
    class << self
      attr_accessor :configuration
      attr_reader :logger

      def configured?
        configuration&.valid? && !@logger.nil?
      end

      def setup_transport!(config)
        require "mihari"

        @logger = Mihari::Logger.new(
          **config.to_transport_options
        )
      rescue LoadError => e
        ::Rails.logger.error("[Mihari] Failed to load mihari-ruby gem: #{e.message}")
      rescue StandardError => e
        ::Rails.logger.error("[Mihari] Failed to initialize transport: #{e.message}")
      end

      def shutdown!
        @logger&.flush
        @logger&.shutdown
        @logger = nil
      rescue StandardError => e
        warn("[Mihari] Error during shutdown: #{e.message}")
      end

      def reset!
        @logger = nil
        @configuration = nil
      end
    end
  end
end

require "mihari/rails/railtie" if defined?(::Rails::Railtie)
