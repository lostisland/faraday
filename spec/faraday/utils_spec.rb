# frozen_string_literal: true

RSpec.describe Faraday::Utils do
  describe 'headers parsing' do
    let(:multi_response_headers) do
      "HTTP/1.x 500 OK\r\nContent-Type: text/html; charset=UTF-8\r\n" \
        "HTTP/1.x 200 OK\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n"
    end

    it 'parse headers for aggregated responses' do
      headers = Faraday::Utils::Headers.new
      headers.parse(multi_response_headers)

      result = headers.to_hash

      expect(result['Content-Type']).to eq('application/json; charset=UTF-8')
    end
  end

  describe 'URI parsing' do
    let(:url) { 'http://example.com/abc' }

    it 'escapes safe buffer' do
      str = FakeSafeBuffer.new('$32,000.00')
      expect(Faraday::Utils.escape(str)).to eq('%2432%2C000.00')
    end

    it 'parses with default parser' do
      with_default_uri_parser(nil) do
        uri = normalize(url)
        expect(uri.host).to eq('example.com')
      end
    end

    it 'parses with URI' do
      with_default_uri_parser(URI) do
        uri = normalize(url)
        expect(uri.host).to eq('example.com')
      end
    end

    it 'parses with block' do
      with_default_uri_parser(->(u) { "booya#{'!' * u.size}" }) do
        expect(normalize(url)).to eq('booya!!!!!!!!!!!!!!!!!!!!!!')
      end
    end

    it 'replaces headers hash' do
      headers = Faraday::Utils::Headers.new('authorization' => 't0ps3cr3t!')
      expect(headers).to have_key('authorization')

      headers.replace('content-type' => 'text/plain')
      expect(headers).not_to have_key('authorization')
    end
  end

  describe '.escape' do
    def escape_with_regexp(str)
      str.gsub(Faraday::Utils::ESCAPE_RE) do |match|
        "%#{match.unpack('H2' * match.bytesize).join('%').upcase}"
      end.tr(' ', '+')
    end

    after { Faraday::Utils.default_space_encoding = nil }

    it 'leaves unreserved characters alone' do
      expect(Faraday::Utils.escape('azAZ09-._~')).to eq('azAZ09-._~')
    end

    it 'escapes reserved characters with uppercase hex' do
      expect(Faraday::Utils.escape("!*'();:@&=+$,/?#[]%")).to eq('%21%2A%27%28%29%3B%3A%40%26%3D%2B%24%2C%2F%3F%23%5B%5D%25')
    end

    it 'escapes every byte like the regexp-based implementation' do
      (0..255).each do |byte|
        [[byte].pack('C').force_encoding(Encoding::UTF_8), [byte].pack('C').b].select(&:valid_encoding?).each do |str|
          expect(Faraday::Utils.escape(str)).to eq(escape_with_regexp(str))
        end
      end
    end

    it 'escapes UTF-8 characters like the regexp-based implementation' do
      [0x80, 0x7FF, 0x800, 0xFFFD, 0x10000, 0x10FFFF].each do |codepoint|
        str = "a #{[codepoint].pack('U')}~"
        expect(Faraday::Utils.escape(str)).to eq(escape_with_regexp(str))
      end
    end

    it 'escapes multibyte characters byte by byte' do
      expect(Faraday::Utils.escape('café 日本 😀')).to eq('caf%C3%A9+%E6%97%A5%E6%9C%AC+%F0%9F%98%80')
    end

    it 'escapes strings in other ASCII-compatible encodings by their bytes' do
      expect(Faraday::Utils.escape('é'.encode(Encoding::ISO_8859_1))).to eq('%E9')
      expect(Faraday::Utils.escape('日本'.encode(Encoding::Shift_JIS))).to eq('%93%FA%96%7B')
    end

    it 'escapes whole characters whose trailing byte is an ASCII letter' do
      expect(Faraday::Utils.escape('ア'.encode(Encoding::Shift_JIS))).to eq('%83%41')
      expect(Faraday::Utils.escape('許'.encode(Encoding::GBK))).to eq('%D4%53')
    end

    it 'keeps the encoding of the given string' do
      [Encoding::UTF_8, Encoding::US_ASCII, Encoding::BINARY, Encoding::ISO_8859_1].each do |encoding|
        expect(Faraday::Utils.escape('a b'.encode(encoding)).encoding).to eq(encoding)
      end
      expect(Faraday::Utils.escape('é'.encode(Encoding::ISO_8859_1)).encoding).to eq(Encoding::ISO_8859_1)
    end

    it 'returns a plain String for String subclasses' do
      expect(Faraday::Utils.escape(Class.new(String).new('abc')).class).to eq(String)
    end

    it 'tells spaces from literal plus signs' do
      expect(Faraday::Utils.escape(' a+b ')).to eq('+a%2Bb+')
    end

    it 'honours default_space_encoding' do
      Faraday::Utils.default_space_encoding = '%20'
      expect(Faraday::Utils.escape(' a+b ')).to eq('%20a%2Bb%20')
    end

    it 'converts non-string values with to_s' do
      expect(Faraday::Utils.escape(nil)).to eq('')
      expect(Faraday::Utils.escape(:'a b')).to eq('a+b')
      expect(Faraday::Utils.escape(4.2)).to eq('4.2')
    end

    it 'raises on strings with an invalid byte sequence' do
      expect { Faraday::Utils.escape((+"caf\xC3").force_encoding(Encoding::UTF_8)) }
        .to raise_error(ArgumentError, /invalid byte sequence/)
    end

    it 'raises on strings in an ASCII-incompatible encoding' do
      expect { Faraday::Utils.escape('a b'.encode(Encoding::UTF_16LE)) }.to raise_error(Encoding::CompatibilityError)
    end
  end

  describe '.deep_merge!' do
    let(:connection_options) { Faraday::ConnectionOptions.new }
    let(:url) do
      {
        url: 'http://example.com/abc',
        headers: { 'Mime-Version' => '1.0' },
        request: { oauth: { consumer_key: 'anonymous' } },
        ssl: { version: '2' }
      }
    end

    it 'recursively merges the headers' do
      connection_options.headers = { user_agent: 'My Agent 1.0' }
      deep_merge = Faraday::Utils.deep_merge!(connection_options, url)

      expect(deep_merge.headers).to eq('Mime-Version' => '1.0', user_agent: 'My Agent 1.0')
    end

    context 'when a target hash has an Options Struct value' do
      let(:request) do
        {
          params_encoder: nil,
          proxy: nil,
          bind: nil,
          timeout: nil,
          open_timeout: nil,
          read_timeout: nil,
          write_timeout: nil,
          boundary: nil,
          oauth: { consumer_key: 'anonymous' },
          context: nil,
          on_data: nil
        }
      end
      let(:ssl) do
        {
          verify: nil,
          ca_file: nil,
          ca_path: nil,
          verify_mode: nil,
          cert_store: nil,
          client_cert: nil,
          client_key: nil,
          certificate: nil,
          private_key: nil,
          verify_depth: nil,
          version: '2',
          min_version: nil,
          max_version: nil,
          verify_hostname: nil,
          hostname: nil,
          ciphers: nil
        }
      end

      it 'does not overwrite an Options Struct value' do
        deep_merge = Faraday::Utils.deep_merge!(connection_options, url)

        expect(deep_merge.request.to_h).to eq(request)
        expect(deep_merge.ssl.to_h).to eq(ssl)
      end
    end
  end

  describe '.deep_merge!' do
    let(:legacy_class) { Faraday::Options.new(:name, :nested) { options nested: Faraday::SSLOptions } }

    it 'deep merges nested hashes' do
      target = { a: { b: 1, c: 2 }, d: 1 }
      result = described_class.deep_merge!(target, a: { c: 3, e: 4 }, f: 5)

      expect(result).to equal(target)
      expect(target).to eq(a: { b: 1, c: 3, e: 4 }, d: 1, f: 5)
    end

    it 'replaces a nested hash when the target value is not mergeable' do
      target = { a: 1 }
      described_class.deep_merge!(target, a: { b: 1 })

      expect(target).to eq(a: { b: 1 })
    end

    it 'deep merges a hash into a nested legacy Options' do
      target = { ssl: Faraday::SSLOptions.from(ca_file: 'ca_file.pem') }
      described_class.deep_merge!(target, ssl: { verify_hostname: false })

      expect(target[:ssl]).to be_a(Faraday::SSLOptions)
      expect(target[:ssl].ca_file).to eq('ca_file.pem')
      expect(target[:ssl].verify_hostname).to be(false)
    end

    it 'does not mutate a nested legacy Options of the target' do
      ssl = Faraday::SSLOptions.new(true)
      described_class.deep_merge!({ ssl: ssl }, ssl: { verify: false })

      expect(ssl.verify).to be(true)
    end

    it 'replaces a legacy Options with a non-hash value' do
      target = { ssl: Faraday::SSLOptions.new(true) }
      described_class.deep_merge!(target, ssl: nil)

      expect(target[:ssl]).to be_nil
    end

    it 'merges into a legacy Options target' do
      target = legacy_class.new('a', Faraday::SSLOptions.from(ca_file: 'ca.pem'))
      result = described_class.deep_merge!(target, name: 'b', nested: { verify: false })

      expect(result).to equal(target)
      expect(target.name).to eq('b')
      expect(target.nested.verify).to be(false)
      expect(target.nested.ca_file).to eq('ca.pem')
    end
  end

  describe '.deep_merge' do
    it 'does not mutate a hash source' do
      source = { a: { b: 1 } }
      result = described_class.deep_merge(source, a: { c: 2 })

      expect(result).to eq(a: { b: 1, c: 2 })
      expect(source).to eq(a: { b: 1 })
    end

    it 'does not mutate a legacy Options source' do
      source = Faraday::ConnectionOptions.new
      source.request = Faraday::RequestOptions.new
      source.request.timeout = 1
      result = described_class.deep_merge(source, request: { open_timeout: 2 })

      expect(result).to be_a(Faraday::ConnectionOptions)
      expect(result.request.timeout).to eq(1)
      expect(result.request.open_timeout).to eq(2)
      expect(source.request.open_timeout).to be_nil
    end
  end
end
