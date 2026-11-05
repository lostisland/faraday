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

  describe 'proxy' do
    let(:proxy_url) { 'http://user:pass@proxy.example.org' }

    it 'keeps the value given to .from, .new, #update and #merge, like the legacy Options' do
      expect(described_class.from(proxy: 'http://proxy.example.org').proxy).to eq('http://proxy.example.org')
      expect(described_class.new(proxy: { uri: 'http://proxy.example.org' }).proxy).to eq(uri: 'http://proxy.example.org')
      expect(options.update(proxy: false).proxy).to be(false)
      expect(options.update(proxy: 'http://proxy.example.org').proxy).to eq('http://proxy.example.org')
    end

    it 'coerces with []= and string keys' do
      options['proxy'] = 'http://proxy.example.org'
      expect(options.proxy).to be_a(Faraday::ProxyOptions)
    end

    it 'treats a falsy value as no proxy with []=' do
      options[:proxy] = 'http://proxy.example.org'
      options[:proxy] = false
      expect(options.proxy).to be_nil
      options[:proxy] = ''
      expect(options.proxy).to be_a(Faraday::ProxyOptions)
      options[:proxy] = nil
      expect(options.proxy).to be_nil
    end

    it 'keeps the assigned value with the proxy= writer' do
      proxy = Faraday::ProxyOptions.from('http://proxy.example.org')
      options.proxy = proxy
      expect(options.proxy).to equal(proxy)
    end

    it 'is replaced, not merged, by #merge and #merge!' do
      options.proxy = Faraday::ProxyOptions.from(proxy_url)
      merged = options.merge(proxy: { user: 'other' })
      expect(merged.proxy).to eq(user: 'other')
      expect(options.proxy.user).to eq('user')
      expect(options.merge(proxy: false).proxy).to be(false)
    end

    it 'is kept as it is by to_hash and inspect' do
      options.update(timeout: 1)
      options.proxy = Faraday::ProxyOptions.from('http://proxy.example.org')
      expect(options.to_hash[:proxy]).to be_a(Faraday::ProxyOptions)
      expect(options.inspect).to eq(
        '#<Faraday::RequestOptions proxy=#<Faraday::ProxyOptions uri=#<URI::HTTP http://proxy.example.org>>, timeout=1>'
      )
    end

    it 'is shared by .from(instance) and #deep_dup, like the legacy Options' do
      options.proxy = Faraday::ProxyOptions.from('http://proxy.example.org')
      expect(described_class.from(options).proxy).to equal(options.proxy)
      expect(options.deep_dup.proxy).to equal(options.proxy)
    end
  end

  describe '#from' do
    it 'works with nil, hash, string keys and instances' do
      expect(described_class.from(nil).to_hash).to eq({})
      expect(described_class.from(timeout: 1).timeout).to eq(1)
      expect(described_class.from('open_timeout' => 2).open_timeout).to eq(2)

      original = described_class.from(timeout: 1)
      expect(described_class.from(original)).to eq(original)
    end

    it 'raises on unknown keys' do
      expect { described_class.from(unknown: 1) }.to raise_error(NoMethodError)
    end

    it 'copies the hashes of the given hash' do
      context = { a: 1 }
      options = described_class.from(context: context, bind: { host: 'localhost' }, oauth: { token: 'x' })
      options.context[:b] = 2
      expect(context).to eq(a: 1)
    end

    it 'copies an instance, sharing nested objects like the legacy Options' do
      original = described_class.from(timeout: 1, bind: { host: 'localhost' }, context: { a: { b: 1 } })
      copy = described_class.from(original)
      expect(copy).not_to equal(original)
      expect(copy.to_hash).to eq(original.to_hash)
      expect(copy.bind).not_to equal(original.bind)
      expect(copy.context[:a]).to equal(original.context[:a])
    end

    it 'builds an empty instance from a falsy value' do
      expect(described_class.from(false).to_hash).to eq({})
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

    it 'allows hash access' do
      options[:timeout] = 5
      expect(options.timeout).to eq(5)
      expect(options[:timeout]).to eq(5)
      expect(options['timeout']).to eq(5)
    end

    it 'raises NameError on unknown keys with []' do
      expect { options[:unknown] }.to raise_error(NameError)
      expect { options[:unknown] = 1 }.to raise_error(NameError)
    end
  end

  describe 'BaseOptions behavior' do
    it 'ignores nil but not false when updating' do
      options.timeout = 1
      expect(options.update(timeout: nil).timeout).to eq(1)
      expect(options.update(timeout: false).timeout).to eq(false)
    end

    it 'replaces the hashes when merging, without modifying the receiver' do
      options.update(context: { a: { b: 1 } }, bind: { host: 'h' }, oauth: { a: 1 })
      merged = options.merge(context: { a: { c: 2 } }, bind: { port: 1 }, oauth: { b: 2 })
      expect(merged.context).to eq(a: { c: 2 })
      expect(merged.bind).to eq(port: 1)
      expect(merged.oauth).to eq(b: 2)
      expect(options.context).to eq(a: { b: 1 })
    end

    it 'does not copy the hashes when merging' do
      context = { a: 1 }
      expect(options.merge!(context: context).context).to equal(context)
    end

    it 'merges another instance' do
      merged = described_class.new(timeout: 1).merge!(described_class.new(open_timeout: 2))
      expect(merged.to_hash).to eq(timeout: 1, open_timeout: 2)
    end

    it 'deep_dup copies the hashes shallowly, like the legacy Options' do
      options.update(context: { a: { b: 1 } })
      copy = options.deep_dup
      copy.context[:x] = 1
      expect(options.context).to eq(a: { b: 1 })
      expect(copy.context[:a]).to equal(options.context[:a])
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

  it 'keeps the Struct-style API of the legacy Options, see StructCompat' do
    expect(options).to be_a(Faraday::StructCompat)
    expect(options).to be_a(Faraday::Options)
  end

  it 'builds from positional arguments, like a Struct' do
    expect(described_class.new('encoder', 'proxy').to_hash).to eq(params_encoder: 'encoder', proxy: 'proxy')
  end

  it 'can be marshaled' do
    options.update(timeout: 1, proxy: 'http://user:pass@proxy.example.org')
    copy = Marshal.load(Marshal.dump(options))
    expect(copy.to_hash).to eq(options.to_hash)
  end
end
