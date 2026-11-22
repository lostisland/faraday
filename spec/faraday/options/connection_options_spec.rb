# frozen_string_literal: true

RSpec.describe Faraday::ConnectionOptions do
  subject(:options) { described_class.new }

  it 'inherits from BaseOptions' do
    expect(described_class.superclass).to eq(Faraday::BaseOptions)
    expect(options).to be_a(Faraday::OptionsLike)
    expect(options).not_to be_a(Struct)
    expect(options).not_to be_a(Faraday::StructCompat)
    expect(described_class::MEMBERS).to eq(
      %i[request proxy ssl builder url parallel_manager params headers builder_class]
    )
  end

  describe 'request and ssl' do
    it 'default to new instances, kept by the reader' do
      expect(options.request).to be_a(Faraday::RequestOptions)
      expect(options.ssl).to be_a(Faraday::SSLOptions)
      expect(options.request).to equal(options.request)
      expect(options.ssl).to equal(options.ssl)
    end

    it 'are coerced from hashes by .from, #update and #merge' do
      expect(described_class.from(request: { timeout: 5 }).request.timeout).to eq(5)
      expect(options.update(ssl: { verify: false }).ssl.verify).to be(false)
      expect(options.merge(request: { open_timeout: 2 }).request.open_timeout).to eq(2)
    end

    it 'skip false and keep the current value' do
      expect(described_class.from(request: false, ssl: false).ssl).to be_a(Faraday::SSLOptions)
      options.update(request: { timeout: 5 }, ssl: { verify: false })
      options.update(request: false)
      options.merge!(ssl: false, proxy: false)

      expect(options.request.timeout).to eq(5)
      expect(options.ssl.verify).to be(false)
    end

    it 'are deep-merged by #merge, without modifying the receiver' do
      options.update(request: { timeout: 5 }, ssl: { verify: false })
      merged = options.merge(request: { open_timeout: 2 }, ssl: { ca_file: 'ca.pem' })

      expect(merged.request.timeout).to eq(5)
      expect(merged.request.open_timeout).to eq(2)
      expect(merged.ssl.verify).to be(false)
      expect(merged.ssl.ca_file).to eq('ca.pem')
      expect(options.request.open_timeout).to be_nil
      expect(options.ssl.ca_file).to be_nil
    end
  end

  describe 'proxy' do
    it 'is coerced to ProxyOptions by .from and #update' do
      expect(described_class.from(proxy: 'http://proxy.example.org').proxy.host).to eq('proxy.example.org')
      expect(options.update(proxy: { uri: 'http://proxy.example.org' }).proxy).to be_a(Faraday::ProxyOptions)
    end

    it 'skips false and keeps the current value' do
      expect(described_class.from(proxy: false).proxy).to be_nil
      options.update(proxy: 'http://proxy.example.org')
      expect(options.update(proxy: false).proxy.host).to eq('proxy.example.org')
    end

    it 'stays a ProxyOptions through .from(instance)' do
      options.proxy = Faraday::ProxyOptions.from('http://proxy.example.org')
      copy = described_class.from(options)

      expect(copy.proxy).to be_a(Faraday::ProxyOptions)
      expect(copy.proxy).not_to equal(options.proxy)
    end
  end

  describe '.from' do
    it 'works with nil, hashes with string keys and instances' do
      expect(described_class.from(nil).url).to be_nil
      expect(described_class.from('url' => 'http://example.com').url).to eq('http://example.com')

      options.update(headers: { 'X-A' => '1' }, request: { timeout: 5 })
      copy = described_class.from(options)
      expect(copy.headers).to eq('X-A' => '1')
      expect(copy.headers).not_to equal(options.headers)
      expect(copy.request).not_to equal(options.request)
    end

    it 'shares the builder, which is not an options object' do
      builder = Faraday::RackBuilder.new
      expect(described_class.from(builder: builder).deep_dup.builder).to equal(builder)
    end

    it 'raises on unknown keys' do
      expect { described_class.from(booya: 1) }.to raise_error(NoMethodError)
    end
  end

  describe '#builder_class and #new_builder' do
    it 'default to RackBuilder' do
      expect(options.builder_class).to eq(Faraday::RackBuilder)
      expect(options.new_builder(nil)).to be_a(Faraday::RackBuilder)
    end

    it 'use the assigned builder class and pass the block' do
      builder_class = Class.new(Faraday::RackBuilder)
      options.builder_class = builder_class
      builder = options.new_builder(proc { |b| b.request :url_encoded })

      expect(builder).to be_a(builder_class)
      expect(builder.handlers).to eq([Faraday::Request::UrlEncoded])
    end
  end

  describe '#to_hash' do
    it 'includes the defaults of request, ssl and builder_class' do
      expect(options.to_hash).to eq(request: {}, ssl: {}, builder_class: Faraday::RackBuilder)
    end
  end

  describe '#merge' do
    it 'deep-merges params and headers' do
      options.update(headers: { 'X-A' => '1' }, params: { a: 1 })
      merged = options.merge(headers: { 'X-B' => '2' }, params: { b: 2 })

      expect(merged.headers).to eq('X-A' => '1', 'X-B' => '2')
      expect(merged.params).to eq(a: 1, b: 2)
      expect(options.headers).to eq('X-A' => '1')
    end
  end

  describe 'Faraday.default_connection_options' do
    after { Faraday.default_connection_options = nil }

    it 'is merged into new connections without being modified' do
      Faraday.default_connection_options = { headers: { 'X-Default' => '1' }, request: { timeout: 9 } }
      conn = Faraday.new('http://example.com', headers: { 'X-Own' => '2' }, request: { open_timeout: 3 })

      expect(conn.headers).to include('X-Default' => '1', 'X-Own' => '2')
      expect(conn.options.timeout).to eq(9)
      expect(conn.options.open_timeout).to eq(3)
      expect(Faraday.default_connection_options.headers).to eq('X-Default' => '1')
      expect(Faraday.default_connection_options.request.open_timeout).to be_nil
    end

    it 'is not overwritten by nil values' do
      Faraday.default_connection_options = { request: { timeout: 9 } }
      conn = Faraday.new('http://example.com', request: nil, headers: nil)

      expect(conn.options.timeout).to eq(9)
    end
  end
end
