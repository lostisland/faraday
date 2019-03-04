# frozen_string_literal: true

RSpec.describe Faraday do
  it 'has a version number' do
    expect(Faraday::VERSION).not_to be nil
  end

  context 'proxies to default_connection' do
    it 'proxies methods that exist on the default_connection' do
      mock_conection = double('Connection')
      Faraday.default_connection = mock_conection

      expect(mock_conection).to receive(:this_should_be_proxied)

      Faraday.this_should_be_proxied
    end

    it 'uses method_missing on Farady if there is no proxyable method' do
      mock_conection = double('Connection')
      Faraday.default_connection = mock_conection

      expect { Faraday.this_method_does_not_exist }.to raise_error(
        NoMethodError,
        "undefined method `this_method_does_not_exist' for Faraday:Module"
      )
    end
  end
end
