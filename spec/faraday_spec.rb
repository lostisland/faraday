# frozen_string_literal: true

RSpec.describe Faraday do
  it 'has a version number' do
    expect(Faraday::VERSION).not_to be nil
  end

  context 'proxies to default_connection' do
    let(:mock_connection) { double('Connection') }
    before do
      Faraday.default_connection = mock_connection
    end

    it 'proxies methods that exist on the default_connection' do
      expect(mock_connection).to receive(:this_should_be_proxied)

      Faraday.this_should_be_proxied
    end

    it 'uses method_missing on Faraday if there is no proxyable method' do
      expected_message =
        if RUBY_VERSION >= '3.4'
          "undefined method 'this_method_does_not_exist' for module Faraday"
        elsif RUBY_VERSION >= '3.3'
          "undefined method `this_method_does_not_exist' for module Faraday"
        else
          "undefined method `this_method_does_not_exist' for Faraday:Module"
        end

      expect { Faraday.this_method_does_not_exist }.to raise_error(NoMethodError, expected_message)
    end

    it 'proxied methods can be accessed' do
      allow(mock_connection).to receive(:this_should_be_proxied)

      expect(Faraday.method(:this_should_be_proxied)).to be_a(Method)
    end

    after do
      Faraday.default_connection = nil
    end
  end

  context 'HTTP verb methods' do
    let(:mock_connection) { double('Connection') }

    before do
      Faraday.default_connection = mock_connection
    end

    (Faraday::METHODS_WITH_QUERY + Faraday::METHODS_WITH_BODY).each do |http_method|
      it "defines .#{http_method} and forwards it to the default_connection" do
        expect(Faraday.singleton_class.instance_methods(false)).to include(http_method.to_sym)

        block = proc { |request| request }
        expect(mock_connection).to receive(http_method) do |*args, &blk|
          expect(args).to eq(['/foo', { page: 1 }, { 'X-Custom' => 'yes' }])
          expect(blk).to be(block)
        end

        Faraday.public_send(http_method, '/foo', { page: 1 }, { 'X-Custom' => 'yes' }, &block)
      end
    end

    after do
      Faraday.default_connection = nil
    end
  end
end
