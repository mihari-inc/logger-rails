# frozen_string_literal: true

module Mihari
  module Rails
    class Configuration
      attr_accessor :token,
                    :source_name,
                    :endpoint,
                    :flush_interval,
                    :batch_size,
                    :gzip,
                    :auto_attach_middleware,
                    :log_active_record,
                    :log_action_controller,
                    :capture_request_id,
                    :capture_user_agent,
                    :capture_ip,
                    :environment,
                    :app_name

      def initialize
        @token = ENV.fetch("MIHARI_TOKEN", nil)
        @source_name = nil
        @endpoint = "https://in.logs.mihari.io"
        @flush_interval = 5
        @batch_size = 100
        @gzip = true
        @auto_attach_middleware = true
        @log_active_record = true
        @log_action_controller = true
        @capture_request_id = true
        @capture_user_agent = true
        @capture_ip = true
        @environment = nil
        @app_name = nil
      end

      def valid?
        !token.nil? && !token.empty?
      end

      def resolved_environment
        @environment || ::Rails.env
      end

      def resolved_app_name
        @app_name || ::Rails.application.class.try(:module_parent_name) || "rails_app"
      end

      def to_transport_options
        {
          token: token,
          source_name: source_name,
          endpoint: endpoint,
          flush_interval: flush_interval,
          batch_size: batch_size,
          gzip: gzip
        }.compact
      end
    end
  end
end
