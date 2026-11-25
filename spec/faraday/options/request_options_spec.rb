# frozen_string_literal: true

RSpec.describe Faraday::RequestOptions do
  subject(:options) { Faraday::RequestOptions.new }

  it 'inherits from BaseOptions' do
    expect(described_class.superclass).to eq(Faraday::BaseOptions)
    expect(options).to be_a(Faraday::OptionsLike)
    expect(options).not_to be_a(Struct)
    expect(described_class::MEMBERS).to eq(
      %i[params_encoder proxy bind timeout open_timeout read_timeout write_timeout boundary oauth context on_data]
    )
  end

  describe 'proxy' do
    let(:proxy_url) { 'http://user:pass@proxy.example.org' }

    it 'is coerced to ProxyOptions by .from, .new, #update and #merge' do
      expect(described_class.from(proxy: 'http://proxy.example.org').proxy).to be_a(Faraday::ProxyOptions)
      expect(described_class.new(proxy: { uri: 'http://proxy.example.org' }).proxy.host).to eq('proxy.example.org')
      expect(options.update(proxy: { user: 'user' }).proxy.user).to eq('user')
      expect(options.merge(proxy: proxy_url).proxy.password).to eq('pass')
    end

    it 'treats a falsy value as no proxy' do
      options.update(proxy: proxy_url)
      expect(options.update(proxy: false).proxy).to be_nil
    end

    it 'raises on unknown proxy keys' do
      expect { options.update(proxy: { booya: 1 }) }.to raise_error(NoMethodError)
    end

    it 'keeps the assigned value with the proxy= writer' do
      proxy = Faraday::ProxyOptions.from('http://proxy.example.org')
      options.proxy = proxy
      expect(options.proxy).to equal(proxy)
    end

    it 'is merged by #merge, without modifying the receiver' do
      options.proxy = Faraday::ProxyOptions.from(proxy_url)
      merged = options.merge(proxy: { user: 'other' })
      expect(merged.proxy).to be_a(Faraday::ProxyOptions)
      expect(merged.proxy.user).to eq('other')
      expect(merged.proxy.uri).to eq(options.proxy.uri)
      expect(options.proxy.user).to eq('user')
    end

    it 'stays a ProxyOptions, not shared, through .from(instance) and #deep_dup' do
      options.proxy = Faraday::ProxyOptions.from(proxy_url)
      [described_class.from(options), options.deep_dup].each do |copy|
        expect(copy.proxy).to be_a(Faraday::ProxyOptions)
        expect(copy.proxy).not_to equal(options.proxy)
        expect(copy.proxy.user).to eq('user')
      end
    end
  end

  describe '#from' do
    it 'works with nil, hash, string keys and instances' do
      expect(described_class.from(nil).to_hash).to eq({})
      expect(described_class.from(timeout: 1).timeout).to eq(1)
      expect(described_class.from('open_timeout' => 2).open_timeout).to eq(2)

      original = described_class.from(timeout: 1)
      expect(described_class.from(original).to_hash).to eq(original.to_hash)
    end

    it 'raises on unknown keys' do
      expect { described_class.from(unknown: 1) }.to raise_error(NoMethodError)
    end

    it 'copies an instance deeply' do
      original = described_class.from(timeout: 1, bind: { host: 'localhost' }, context: { a: { b: 1 } })
      copy = described_class.from(original)
      expect(copy).not_to equal(original)
      expect(copy.to_hash).to eq(original.to_hash)
      expect(copy.context[:a]).not_to equal(original.context[:a])
    end
  end

  describe 'accessors' do
    it 'reads and writes every member' do
      encoder = Faraday::FlatParamsEncoder
      options.update(params_encoder: encoder, bind: { host: 'h', port: 1 }, timeout: 1, open_timeout: 2,
                     read_timeout: 3, write_timeout: 4, boundary: 'b', oauth: { a: 1 }, context: { c: 1 })
      expect(options.to_hash).to include(
        params_encoder: encoder, bind: { host: 'h', port: 1 }, timeout: 1, open_timeout: 2,
        read_timeout: 3, write_timeout: 4, boundary: 'b', oauth: { a: 1 }, context: { c: 1 }
      )
    end
  end

  describe 'Struct-style API used by adapters and middleware, see StructCompat' do
    it 'reads members with [], like env[:request][:proxy] and request_timeout' do
      options.timeout = 5
      expect(options[:timeout]).to eq(5)
      expect(options['timeout']).to eq(5)
      expect { options[:unknown] }.to raise_error(NameError)
    end

    it 'writes members with []=, like conn.options[:timeout] = 5' do
      options[:timeout] = 5
      options['open_timeout'] = 2
      expect(options.timeout).to eq(5)
      expect(options.open_timeout).to eq(2)
      expect { options[:unknown] = 1 }.to raise_error(NameError)
    end

    it 'coerces the proxy written with []=, like the legacy RequestOptions' do
      options[:proxy] = 'http://proxy.example.org'
      expect(options.proxy).to be_a(Faraday::ProxyOptions)
      expect(options.proxy.uri).to eq(URI('http://proxy.example.org'))
      options[:proxy] = false
      expect(options.proxy).to be_nil
    end

    it 'fetches members, like env[:request].fetch(:oauth, true)' do
      expect(options.fetch(:oauth, true)).to be(true)
      options.oauth = { token: 'x' }
      expect(options.fetch(:oauth, true)).to eq(token: 'x')
    end
  end

  describe 'BaseOptions behavior' do
    it 'ignores nil but not false when updating' do
      options.timeout = 1
      expect(options.update(timeout: nil).timeout).to eq(1)
      expect(options.update(timeout: false).timeout).to eq(false)
    end

    it 'deep merges the hashes, without modifying the receiver' do
      options.update(context: { a: { b: 1 } }, bind: { host: 'h' })
      merged = options.merge(context: { a: { c: 2 } }, bind: { port: 1 })
      expect(merged.context).to eq(a: { b: 1, c: 2 })
      expect(merged.bind).to eq(host: 'h', port: 1)
      expect(options.context).to eq(a: { b: 1 })
    end

    it 'merges another instance' do
      merged = described_class.new(timeout: 1).merge!(described_class.new(open_timeout: 2))
      expect(merged.to_hash).to eq(timeout: 1, open_timeout: 2)
    end
  end

  describe '#stream_response?' do
    it 'is true only when on_data is a Proc' do
      expect(options.stream_response?).to be(false)
      options.on_data = proc {}
      expect(options.stream_response?).to be(true)
      options.on_data = ->(*) {}
      expect(options.stream_response?).to be(true)
      options.on_data = 1.method(:+)
      expect(options.stream_response?).to be(false)
    end
  end

  it 'can be marshaled' do
    options.update(timeout: 1, proxy: 'http://user:pass@proxy.example.org')
    copy = Marshal.load(Marshal.dump(options))
    expect(copy.to_hash).to eq(options.to_hash)
  end
end
