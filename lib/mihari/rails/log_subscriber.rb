# frozen_string_literal: true

module Mihari
  module Rails
    class LogSubscriber < ActiveSupport::LogSubscriber
      def process_action(event)
        return unless Mihari::Rails.configured?

        payload = event.payload
        entry = {
          level: status_level(payload[:status]),
          message: format_action_message(payload, event.duration),
          action_controller: {
            controller: payload[:controller],
            action: payload[:action],
            format: payload[:format],
            method: payload[:method],
            path: payload[:path],
            status: payload[:status],
            duration_ms: event.duration.round(2),
            view_runtime_ms: payload[:view_runtime]&.round(2),
            db_runtime_ms: payload[:db_runtime]&.round(2)
          },
          rails: {
            environment: Mihari::Rails.configuration.resolved_environment,
            app_name: Mihari::Rails.configuration.resolved_app_name
          }
        }

        add_request_id(entry, payload)
        Mihari::Rails.logger&.log(entry)
      end

      def sql(event)
        return unless Mihari::Rails.configured?
        return unless Mihari::Rails.configuration.log_active_record

        payload = event.payload
        return if payload[:name] == "SCHEMA" || payload[:name] == "CACHE"

        entry = {
          level: "debug",
          message: "SQL #{payload[:name]} (#{event.duration.round(2)}ms)",
          active_record: {
            name: payload[:name],
            sql: payload[:sql],
            duration_ms: event.duration.round(2),
            cached: payload[:cached] || false
          },
          rails: {
            environment: Mihari::Rails.configuration.resolved_environment,
            app_name: Mihari::Rails.configuration.resolved_app_name
          }
        }

        Mihari::Rails.logger&.log(entry)
      end

      private

      def format_action_message(payload, duration)
        parts = [
          payload[:controller],
          "#",
          payload[:action],
          " ",
          payload[:status].to_s,
          " in ",
          duration.round(2).to_s,
          "ms"
        ]
        parts.join
      end

      def status_level(status)
        case status
        when 200..399 then "info"
        when 400..499 then "warn"
        else "error"
        end
      end

      def add_request_id(entry, payload)
        return unless Mihari::Rails.configuration.capture_request_id

        request_id = payload[:request]&.request_id rescue nil
        entry[:request_id] = request_id if request_id
      end
    end
  end
end
