# frozen_string_literal: true

module Mihari
  module Rails
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        request_start = clock_monotonic
        status, headers, response = @app.call(env)
        duration_ms = ((clock_monotonic - request_start) * 1000).round(2)

        log_request(env, status, duration_ms)

        [status, headers, response]
      rescue StandardError => e
        duration_ms = ((clock_monotonic - request_start) * 1000).round(2)
        log_request(env, 500, duration_ms, error: e)
        raise
      end

      private

      def log_request(env, status, duration_ms, error: nil)
        return unless Mihari::Rails.configured?

        config = Mihari::Rails.configuration
        request = ActionDispatch::Request.new(env)

        entry = build_entry(request, status, duration_ms, config)
        entry[:error] = format_error(error) if error

        Mihari::Rails.logger&.log(entry)
      rescue StandardError => e
        ::Rails.logger.warn("[Mihari] Failed to log request: #{e.message}")
      end

      def build_entry(request, status, duration_ms, config)
        entry = {
          level: status_to_level(status),
          message: "#{request.method} #{request.path} #{status} #{duration_ms}ms",
          http: {
            method: request.method,
            path: request.path,
            status: status,
            duration_ms: duration_ms
          },
          rails: {
            environment: config.resolved_environment,
            app_name: config.resolved_app_name
          }
        }

        entry[:http][:request_id] = request.request_id if config.capture_request_id
        entry[:http][:user_agent] = request.user_agent if config.capture_user_agent
        entry[:http][:ip] = request.remote_ip if config.capture_ip

        entry
      end

      def status_to_level(status)
        case status
        when 200..399 then "info"
        when 400..499 then "warn"
        else "error"
        end
      end

      def format_error(error)
        {
          class: error.class.name,
          message: error.message,
          backtrace: error.backtrace&.first(10)
        }
      end

      def clock_monotonic
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
