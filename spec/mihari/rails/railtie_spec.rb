# frozen_string_literal: true

require "spec_helper"

RSpec.describe Mihari::Rails::Railtie do
  describe "configuration" do
    it "provides config.mihari namespace on Rails config" do
      expect(::Rails.configuration).to respond_to(:mihari)
    end
  end

  describe Mihari::Rails::Configuration do
    subject(:config) { described_class.new }

    it "has sensible defaults" do
      expect(config.endpoint).to eq("https://in.logs.mihari.io")
      expect(config.flush_interval).to eq(5)
      expect(config.batch_size).to eq(100)
      expect(config.gzip).to be(true)
      expect(config.auto_attach_middleware).to be(true)
      expect(config.log_active_record).to be(true)
      expect(config.log_action_controller).to be(true)
      expect(config.capture_request_id).to be(true)
      expect(config.capture_user_agent).to be(true)
      expect(config.capture_ip).to be(true)
    end

    it "reads token from MIHARI_TOKEN env var" do
      allow(ENV).to receive(:fetch).with("MIHARI_TOKEN", nil).and_return("env-token-123")

      new_config = described_class.new
      expect(new_config.token).to eq("env-token-123")
    end

    describe "#valid?" do
      it "returns false when token is nil" do
        config.token = nil
        expect(config).not_to be_valid
      end

      it "returns false when token is empty" do
        config.token = ""
        expect(config).not_to be_valid
      end

      it "returns true when token is present" do
        config.token = "my-token"
        expect(config).to be_valid
      end
    end

    describe "#to_transport_options" do
      before { config.token = "test-token" }

      it "returns a hash suitable for Mihari::Logger" do
        options = config.to_transport_options

        expect(options).to eq(
          token: "test-token",
          endpoint: "https://in.logs.mihari.io",
          flush_interval: 5,
          batch_size: 100,
          gzip: true
        )
      end

      it "includes source_name when set" do
        config.source_name = "my-service"
        options = config.to_transport_options

        expect(options[:source_name]).to eq("my-service")
      end

      it "omits nil source_name" do
        config.source_name = nil
        options = config.to_transport_options

        expect(options).not_to have_key(:source_name)
      end
    end
  end

  describe Mihari::Rails do
    let(:mock_logger) { instance_double("Mihari::Logger", flush: nil, shutdown: nil) }

    describe ".configured?" do
      it "returns false when configuration is nil" do
        Mihari::Rails.configuration = nil
        expect(Mihari::Rails).not_to be_configured
      end

      it "returns false when token is missing" do
        config = Mihari::Rails::Configuration.new
        config.token = nil
        Mihari::Rails.configuration = config
        expect(Mihari::Rails).not_to be_configured
      end
    end

    describe ".shutdown!" do
      it "flushes and shuts down the logger" do
        allow(Mihari::Rails).to receive(:logger).and_return(mock_logger)
        Mihari::Rails.instance_variable_set(:@logger, mock_logger)

        Mihari::Rails.shutdown!

        expect(mock_logger).to have_received(:flush)
        expect(mock_logger).to have_received(:shutdown)
      end

      it "sets logger to nil after shutdown" do
        Mihari::Rails.instance_variable_set(:@logger, mock_logger)
        allow(mock_logger).to receive(:flush)
        allow(mock_logger).to receive(:shutdown)

        Mihari::Rails.shutdown!

        expect(Mihari::Rails.logger).to be_nil
      end
    end

    describe ".reset!" do
      it "clears logger and configuration" do
        Mihari::Rails.instance_variable_set(:@logger, mock_logger)
        Mihari::Rails.configuration = Mihari::Rails::Configuration.new

        Mihari::Rails.reset!

        expect(Mihari::Rails.logger).to be_nil
        expect(Mihari::Rails.configuration).to be_nil
      end
    end
  end
end
