# frozen_string_literal: true

module Mihari
  module Rails
    module TaggedLogging
      module Formatter
        def call(severity, timestamp, progname, msg)
          entry = build_tagged_entry(severity, timestamp, msg)
          Mihari::Rails.logger&.log(entry)
          super
        end

        private

        def build_tagged_entry(severity, timestamp, msg)
          {
            level: normalize_level(severity),
            message: msg.is_a?(String) ? msg : msg.inspect,
            tags: current_tags.dup,
            rails: {
              environment: Mihari::Rails.configuration.resolved_environment,
              app_name: Mihari::Rails.configuration.resolved_app_name
            }
          }
        end

        def normalize_level(severity)
          case severity.to_s.downcase
          when "debug" then "debug"
          when "info" then "info"
          when "warn", "warning" then "warn"
          when "error" then "error"
          when "fatal" then "fatal"
          else "info"
          end
        end
      end

      def self.install(logger)
        return unless logger.respond_to?(:formatter)
        return unless logger.formatter.respond_to?(:current_tags)

        logger.formatter.extend(Formatter)
        logger
      end
    end
  end
end
