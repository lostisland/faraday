# frozen_string_literal: true

RSpec.describe Faraday::Adapter do
  let(:adapter) { Faraday::Adapter.new }

  context '#reconfigure_connection?' do
    let(:all_keys) do
      (Faraday::ConnectionOptions.members + Faraday::RequestOptions.members).uniq
    end
    let(:non_request_keys) { all_keys - Faraday::Adapter::CONNECTION_OPTIONS }

    it 'is not truthy with nil env request value' do
      expect(!!reconfigure_connection?(request: nil)).to eq(false)
    end

    it 'is not truthy with nil env' do
      expect(!!reconfigure_connection?(nil)).to eq(false)
    end

    it 'is not truthy with unimportant request keys' do
      env = {}
      non_request_keys.each do |key|
        env[key] = :set
      end
      env[:request] = env

      expect(!!reconfigure_connection?(env)).to eq(false)
    end

    Faraday::Adapter::CONNECTION_OPTIONS.each do |key|
      it "is truthy with request #{key.inspect} key" do
        env = { request: { key => true } }
        expect(!!reconfigure_connection?(env)).to eq(true)

        non_request_keys.each do |k|
          env[:request][k] = :set
        end

        expect(!!reconfigure_connection?(env)).to eq(true)
      end
    end

    def reconfigure_connection?(*args)
      adapter.send(:reconfigure_connection?, *args)
    end
  end

  context '#request_timeout' do
    let(:request) { {} }
    it 'gets :read timeout' do
      expect(timeout(:read)).to eq(nil)

      request[:timeout] = 5
      request[:write_timeout] = 1

      expect(timeout(:read)).to eq(5)

      request[:read_timeout] = 2

      expect(timeout(:read)).to eq(2)
    end

    it 'gets :open timeout' do
      expect(timeout(:open)).to eq(nil)

      request[:timeout] = 5
      request[:write_timeout] = 1

      expect(timeout(:open)).to eq(5)

      request[:open_timeout] = 2

      expect(timeout(:open)).to eq(2)
    end

    it 'gets :write timeout' do
      expect(timeout(:write)).to eq(nil)

      request[:timeout] = 5
      request[:read_timeout] = 1

      expect(timeout(:write)).to eq(5)

      request[:write_timeout] = 2

      expect(timeout(:write)).to eq(2)
    end

    it 'attempts unknown timeout type' do
      expect { timeout(:unknown) }.to raise_error(ArgumentError)
    end

    def timeout(type)
      adapter.send(:request_timeout, type, request)
    end
  end
end
