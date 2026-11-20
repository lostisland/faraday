# frozen_string_literal: true

RSpec.describe Faraday::ProxyOptions do
  describe '#from' do
    it 'works with string' do
      options = Faraday::ProxyOptions.from 'http://user:pass@example.org'
      expect(options.user).to eq('user')
      expect(options.password).to eq('pass')
      expect(options.uri).to be_a_kind_of(URI)
      expect(options.path).to eq('')
      expect(options.port).to eq(80)
      expect(options.host).to eq('example.org')
      expect(options.scheme).to eq('http')
      expect(options.inspect).to match('#<Faraday::ProxyOptions uri=')
    end

    it 'defaults to http' do
      options = Faraday::ProxyOptions.from 'example.org'
      expect(options.port).to eq(80)
      expect(options.host).to eq('example.org')
      expect(options.scheme).to eq('http')
    end

    it 'works with nil' do
      options = Faraday::ProxyOptions.from nil
      expect(options).to be_a_kind_of(Faraday::ProxyOptions)
      expect(options.inspect).to eq('#<Faraday::ProxyOptions (empty)>')
    end

    it 'works with hash' do
      hash = { user: 'user', password: 'pass', uri: 'http://@example.org' }
      options = Faraday::ProxyOptions.from(hash)
      expect(options.user).to eq('user')
      expect(options.password).to eq('pass')
      expect(options.uri).to be_a_kind_of(URI)
      expect(options.path).to eq('')
      expect(options.port).to eq(80)
      expect(options.host).to eq('example.org')
      expect(options.scheme).to eq('http')
      expect(options.inspect).to match('#<Faraday::ProxyOptions uri=')
    end

    it 'works with option' do
      opt_arg = { user: 'user', password: 'pass', uri: 'http://@example.org' }
      option = Faraday::ConnectionOptions.from(proxy: opt_arg)
      options = Faraday::ProxyOptions.from(option.proxy)
      expect(options.user).to eq('user')
      expect(options.password).to eq('pass')
      expect(options.uri).to be_a_kind_of(URI)
      expect(options.path).to eq('')
      expect(options.port).to eq(80)
      expect(options.host).to eq('example.org')
      expect(options.scheme).to eq('http')
      expect(options.inspect).to match('#<Faraday::ProxyOptions uri=')
    end

    it 'works with no auth' do
      proxy = Faraday::ProxyOptions.from 'http://example.org'
      expect(proxy.user).to be_nil
      expect(proxy.password).to be_nil
    end

    it 'treats empty string as nil' do
      proxy = nil
      proxy_string = proxy.to_s # => empty string
      options = Faraday::ProxyOptions.from proxy_string
      expect(options).to be_a_kind_of(Faraday::ProxyOptions)
      expect(options.inspect).to eq('#<Faraday::ProxyOptions (empty)>')
    end
  end

  it 'inherits from BaseOptions' do
    expect(described_class.superclass).to eq(Faraday::BaseOptions)
    expect(described_class.new).to be_a(Faraday::OptionsLike)
    expect(described_class.new).to be_a(Faraday::StructCompat)
    expect(described_class.new).to be_a(Faraday::Options)
    expect(described_class::MEMBERS).to eq(%i[uri user password])
  end

  describe '#from' do
    it 'works with a URI' do
      options = described_class.from(URI('http://user:pass@example.org:8080'))
      expect(options.uri).to eq(URI('http://user:pass@example.org:8080'))
      expect(options.user).to eq('user')
      expect(options.password).to eq('pass')
    end

    it 'coerces the uri of a hash' do
      options = described_class.from(uri: 'http://example.org', user: 'explicit')
      expect(options.uri).to be_a(URI::HTTP)
      expect(options.user).to eq('explicit')
    end

    it 'coerces the uri of a hash with string keys' do
      options = described_class.from('uri' => 'http://example.org')
      expect(options.uri).to be_a(URI::HTTP)
    end

    it 'treats false as nil' do
      expect(described_class.from(false).inspect).to eq('#<Faraday::ProxyOptions (empty)>')
    end

    it 'raises on an invalid uri' do
      expect { described_class.from(uri: :bad_uri) }.to raise_error(ArgumentError)
    end

    it 'raises on unknown keys' do
      expect { described_class.from(unknown: 1) }.to raise_error(NoMethodError)
    end

    it 'returns a copy of an instance' do
      original = described_class.from('http://user:pass@example.org')
      copy = described_class.from(original)
      expect(copy).not_to equal(original)
      expect(copy.to_hash).to eq(original.to_hash)
    end

    it 'works with legacy options' do
      legacy = Faraday::Options.new(:uri).new('http://example.org')
      expect(described_class.from(legacy).host).to eq('example.org')
    end
  end

  describe 'URI delegators' do
    subject(:options) { described_class.from('http://example.org:8080/path') }

    it 'reads from the uri' do
      expect([options.scheme, options.host, options.port, options.path]).to eq(['http', 'example.org', 8080, '/path'])
    end

    it 'writes to the uri' do
      options.scheme = 'https'
      options.host = 'proxy.example.org'
      options.port = 9090
      options.path = '/other'
      expect(options.uri.to_s).to eq('https://proxy.example.org:9090/other')
    end

    it 'raises without a uri' do
      expect { described_class.new.host }.to raise_error(NoMethodError)
    end
  end

  describe 'user and password' do
    it 'are derived lazily from the unescaped uri' do
      options = described_class.new(uri: 'http://a%40b:pw%20d@example.org')
      expect(options.user).to eq('a@b')
      expect(options.password).to eq('pw d')
    end

    it 'are nil without a uri' do
      expect(described_class.new.user).to be_nil
      expect(described_class.new.password).to be_nil
    end

    it 'prefer explicit values' do
      options = described_class.new(uri: 'http://a:b@example.org')
      options.user = 'explicit'
      expect(options.user).to eq('explicit')
      expect(options.password).to eq('b')
    end

    it 'are included in to_hash' do
      options = described_class.new(uri: 'http://a:b@example.org')
      expect(options.to_hash).to eq(uri: URI('http://a:b@example.org'), user: 'a', password: 'b')
    end
  end

  describe 'BaseOptions behavior' do
    it 'updates and merges' do
      options = described_class.from('http://example.org')
      expect(options.update(user: 'u', password: 'p').to_hash).to include(user: 'u', password: 'p')
      merged = options.merge(uri: 'http://other.org')
      expect(merged.host).to eq('other.org')
      expect(options.host).to eq('example.org')
    end

    it 'ignores nil values when updating' do
      options = described_class.new(user: 'u')
      expect(options.update(user: nil).user).to eq('u')
    end

    it 'deep_dup creates an independent copy' do
      options = described_class.from('http://user:pass@example.org')
      copy = options.deep_dup
      copy.user = 'other'
      expect(options.user).to eq('user')
      expect(copy.to_hash).to include(password: 'pass')
    end

    it 'inspects empty options' do
      expect(described_class.new.inspect).to eq('#<Faraday::ProxyOptions (empty)>')
    end
  end

  describe 'Struct-style API, see StructCompat' do
    it 'builds from positional arguments, like a Struct' do
      uri = URI('http://example.org')
      expect(described_class.new(uri, 'u', 'p').to_hash).to eq(uri: uri, user: 'u', password: 'p')
    end

    it 'to_h includes nil members' do
      expect(described_class.new.to_h).to eq(uri: nil, user: nil, password: nil)
    end

    it 'compares members for equality' do
      expect(described_class.from('http://example.org')).to eq(described_class.from('http://example.org'))
      expect(described_class.from('http://example.org')).not_to eq(described_class.from('http://other.org'))
    end

    it 'exposes the derived user and password through the Struct-style readers' do
      options = described_class.from('http://u:p@example.org')
      expect(options.values).to eq([URI('http://u:p@example.org'), 'u', 'p'])
      expect(options.fetch(:user)).to eq('u')
      expect(options.key?(:password)).to be(true)
    end
  end

  describe 'hash access' do
    subject(:options) { described_class.from('http://user:pass@example.org') }

    it 'reads members by symbol or string' do
      expect(options[:uri]).to eq(URI('http://user:pass@example.org'))
      expect(options['user']).to eq('user')
    end

    it 'writes members' do
      options[:user] = 'other'
      expect(options.user).to eq('other')
    end

    it 'raises on unknown keys' do
      expect { options[:host] }.to raise_error(NameError)
      expect { options[:host] = 'x' }.to raise_error(NameError)
    end
  end

  it 'allows hash access' do
    proxy = Faraday::ProxyOptions.from 'http://a%40b:pw%20d@example.org'
    expect(proxy.user).to eq('a@b')
    expect(proxy[:user]).to eq('a@b')
    expect(proxy.password).to eq('pw d')
    expect(proxy[:password]).to eq('pw d')
  end

  it 'preserves literal plus signs in userinfo' do
    proxy = Faraday::ProxyOptions.from 'http://a+b:pw+d%2B@example.org'
    expect(proxy.user).to eq('a+b')
    expect(proxy.password).to eq('pw+d+')
  end
end
