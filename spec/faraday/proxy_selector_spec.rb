# frozen_string_literal: true

RSpec.shared_examples 'ProxySelector::Nil' do |proxy_sel|
  it 'is the right type' do
    expect(proxy_sel).to be_a(Faraday::ProxySelector::Nil)
  end

  it 'returns no proxy for http url' do
    expect(proxy_sel.proxy_for_url(http_request_url)).to be_nil
    expect(proxy_sel.proxy_for(http_request_uri)).to be_nil
  end

  it 'returns no proxy for https url' do
    expect(proxy_sel.proxy_for_url(https_request_url)).to be_nil
    expect(proxy_sel.proxy_for(https_request_uri)).to be_nil
  end

  it 'doesnt use proxy for http url' do
    expect(proxy_sel.use_for_url?(http_request_url)).to eq(false)
    expect(proxy_sel.use_for?(http_request_uri)).to eq(false)
  end

  it 'doesnt use proxy for https url' do
    expect(proxy_sel.use_for_url?(https_request_url)).to eq(false)
    expect(proxy_sel.use_for?(https_request_uri)).to eq(false)
  end
end

RSpec.shared_examples 'ProxySelector::Single' do |proxy_sel, expected_user, expected_pass|
  it 'is the right type' do
    expect(proxy_sel).to be_a(Faraday::ProxySelector::Single)
  end

  it 'fetches proxy for http url' do
    proxy = proxy_sel.proxy_for(http_request_uri)
    expect(proxy_sel.proxy_for_url(http_request_url)).to eq(proxy)
    expect(proxy).not_to be_nil
    expect(proxy.host).to eq('proxy.com')
    expect(proxy.user).to eq(expected_user)
    expect(proxy.password).to eq(expected_pass)
  end

  it 'fetches proxy for https url' do
    proxy = proxy_sel.proxy_for(https_request_uri)
    expect(proxy_sel.proxy_for_url(https_request_url)).to eq(proxy)
    expect(proxy).not_to be_nil
    expect(proxy.host).to eq('proxy.com')
    expect(proxy.user).to eq(expected_user)
    expect(proxy.password).to eq(expected_pass)
  end

  it 'uses proxy for http url' do
    expect(proxy_sel.use_for_url?(http_request_url)).to eq(true)
    expect(proxy_sel.use_for?(http_request_uri)).to eq(true)
  end

  it 'uses proxy for https url' do
    expect(proxy_sel.use_for_url?(https_request_url)).to eq(true)
    expect(proxy_sel.use_for?(https_request_uri)).to eq(true)
  end
end

RSpec.describe Faraday::ProxySelector do
  let(:http_request_url) { 'http://http.example.com' }
  let(:https_request_url) { 'https://https.example.com' }
  let(:http_request_uri) { Faraday::Utils.URI(http_request_url) }
  let(:https_request_uri) { Faraday::Utils.URI(https_request_url) }

  before do
    @ignore_env_proxy = Faraday.ignore_env_proxy
  end

  after do
    Faraday.ignore_env_proxy = @ignore_env_proxy
  end

  context '#with_env with env disabled' do
    Faraday.ignore_env_proxy = true
    proxy = Faraday.proxy_with_env(nil)
    include_examples 'ProxySelector::Nil', proxy
  end

  context '#none' do
    include_examples 'ProxySelector::Nil', Faraday::ProxySelector::Nil.new
  end

  context '#to_url without user auth' do
    proxy = Faraday.proxy_to_url('http://proxy.com')
    include_examples 'ProxySelector::Single', proxy, nil, nil
  end

  context '#to_url with user auth in proxy url' do
    proxy = Faraday.proxy_to_url('http://u%3A1:p%3A2@proxy.com')
    include_examples 'ProxySelector::Single', proxy, 'u:1', 'p:2'
  end

  context '#to_url with explicit user auth' do
    proxy = Faraday.proxy_to_url('http://proxy.com',
                                 user: 'u:1', password: 'p:2')
    include_examples 'ProxySelector::Single', proxy, 'u:1', 'p:2'
  end
end
