# frozen_string_literal: true

RSpec.describe Faraday::RequestOptions do
  subject(:options) { Faraday::RequestOptions.new }

  context '#fetch_timeout' do
    it 'gets :read timeout' do
      expect(options.fetch_timeout(:read)).to eq(nil)

      options[:timeout] = 5
      options[:write_timeout] = 1

      expect(options.fetch_timeout(:read)).to eq(5)

      options[:read_timeout] = 2

      expect(options.fetch_timeout(:read)).to eq(2)
    end

    it 'gets :open timeout' do
      expect(options.fetch_timeout(:open)).to eq(nil)

      options[:timeout] = 5
      options[:write_timeout] = 1

      expect(options.fetch_timeout(:open)).to eq(5)

      options[:open_timeout] = 2

      expect(options.fetch_timeout(:open)).to eq(2)
    end

    it 'gets :write timeout' do
      expect(options.fetch_timeout(:write)).to eq(nil)

      options[:timeout] = 5
      options[:read_timeout] = 1

      expect(options.fetch_timeout(:write)).to eq(5)

      options[:write_timeout] = 2

      expect(options.fetch_timeout(:write)).to eq(2)
    end
  end

  it 'allows to set the request proxy' do
    expect(options.proxy).to be_nil

    expect { options[:proxy] = { booya: 1 } }.to raise_error(NoMethodError)

    options[:proxy] = { user: 'user' }
    expect(options.proxy).to be_a_kind_of(Faraday::ProxyOptions)
    expect(options.proxy.user).to eq('user')

    options.proxy = nil
    expect(options.proxy).to be_nil
    expect(options.inspect).to eq('#<Faraday::RequestOptions (empty)>')
  end
end
