# frozen_string_literal: true

require "spec_helper"

RSpec.describe Mihari::Rails::Middleware do
  let(:inner_app) { ->(env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] } }
  let(:middleware) { described_class.new(inner_app) }
  let(:mock_logger) { instance_double("Mihari::Logger", log: nil, flush: nil, shutdown: nil) }
  let(:configuration) { Mihari::Rails::Configuration.new }

  let(:env) do
    Rack::MockRequest.env_for(
      "/users/1",
      method: "GET",
      "HTTP_USER_AGENT" => "TestAgent/1.0",
      "REMOTE_ADDR" => "127.0.0.1",
      "action_dispatch.request_id" => "req-abc-123"
    )
  end

  before do
    configuration.token = "test-token"
    configuration.environment = "test"
    configuration.app_name = "test_app"
    Mihari::Rails.configuration = configuration
    allow(Mihari::Rails).to receive(:logger).and_return(mock_logger)
    allow(Mihari::Rails).to receive(:configured?).and_return(true)
  end

  describe "#call" do
    it "passes the request through to the inner app" do
      status, _headers, body = middleware.call(env)

      expect(status).to eq(200)
      expect(body).to eq(["OK"])
    end

    it "logs the request to mihari" do
      middleware.call(env)

      expect(mock_logger).to have_received(:log).with(
        hash_including(
          level: "info",
          message: a_string_matching(%r{GET /users/1 200 \d+(\.\d+)?ms}),
          http: hash_including(
            method: "GET",
            path: "/users/1",
            status: 200
          )
        )
      )
    end

    it "captures duration in milliseconds" do
      middleware.call(env)

      expect(mock_logger).to have_received(:log).with(
        hash_including(
          http: hash_including(
            duration_ms: a_value > 0
          )
        )
      )
    end

    it "includes rails metadata" do
      middleware.call(env)

      expect(mock_logger).to have_received(:log).with(
        hash_including(
          rails: {
            environment: "test",
            app_name: "test_app"
          }
        )
      )
    end

    it "captures request_id when enabled" do
      middleware.call(env)

      expect(mock_logger).to have_received(:log).with(
        hash_including(
          http: hash_including(request_id: "req-abc-123")
        )
      )
    end

    it "captures user_agent when enabled" do
      middleware.call(env)

      expect(mock_logger).to have_received(:log).with(
        hash_including(
          http: hash_including(user_agent: "TestAgent/1.0")
        )
      )
    end

    it "captures remote IP when enabled" do
      middleware.call(env)

      expect(mock_logger).to have_received(:log).with(
        hash_including(
          http: hash_including(ip: "127.0.0.1")
        )
      )
    end

    it "omits request_id when capture_request_id is false" do
      configuration.capture_request_id = false
      middleware.call(env)

      expect(mock_logger).to have_received(:log) do |entry|
        expect(entry[:http]).not_to have_key(:request_id)
      end
    end

    it "omits user_agent when capture_user_agent is false" do
      configuration.capture_user_agent = false
      middleware.call(env)

      expect(mock_logger).to have_received(:log) do |entry|
        expect(entry[:http]).not_to have_key(:user_agent)
      end
    end

    it "omits ip when capture_ip is false" do
      configuration.capture_ip = false
      middleware.call(env)

      expect(mock_logger).to have_received(:log) do |entry|
        expect(entry[:http]).not_to have_key(:ip)
      end
    end

    context "when inner app returns 4xx status" do
      let(:inner_app) { ->(env) { [404, {}, ["Not Found"]] } }

      it "logs with warn level" do
        middleware.call(env)

        expect(mock_logger).to have_received(:log).with(
          hash_including(level: "warn")
        )
      end
    end

    context "when inner app returns 5xx status" do
      let(:inner_app) { ->(env) { [500, {}, ["Error"]] } }

      it "logs with error level" do
        middleware.call(env)

        expect(mock_logger).to have_received(:log).with(
          hash_including(level: "error")
        )
      end
    end

    context "when inner app raises an exception" do
      let(:inner_app) { ->(env) { raise StandardError, "boom" } }

      it "re-raises the exception" do
        expect { middleware.call(env) }.to raise_error(StandardError, "boom")
      end

      it "logs the error before re-raising" do
        middleware.call(env) rescue nil

        expect(mock_logger).to have_received(:log).with(
          hash_including(
            level: "error",
            error: hash_including(
              class: "StandardError",
              message: "boom"
            )
          )
        )
      end
    end

    context "when mihari is not configured" do
      before do
        allow(Mihari::Rails).to receive(:configured?).and_return(false)
      end

      it "does not log but still passes the request through" do
        status, _headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(["OK"])
        expect(mock_logger).not_to have_received(:log)
      end
    end
  end
end
