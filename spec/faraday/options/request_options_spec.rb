# frozen_string_literal: true

RSpec.describe Faraday::RequestOptions do
  it 'allows to set the request proxy' do
    options = Faraday::RequestOptions.new
    expect(options.proxy).to be_nil

    expect { options[:proxy] = { booya: 1 } }.to raise_error(NoMethodError)

    options[:proxy] = { user: 'user' }
    expect(options.proxy).to be_a_kind_of(Faraday::ProxyOptions)
    expect(options.proxy.user).to eq('user')

    options.proxy = nil
    expect(options.proxy).to be_nil
  end
end