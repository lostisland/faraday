shared_examples 'initializer with url' do
  context 'with simple url' do
    let(:address) { 'http://sushi.com' }

    it { expect(subject.host).to eq('sushi.com') }
    it { expect(subject.port).to eq(80) }
    it { expect(subject.scheme).to eq('http') }
    it { expect(subject.path_prefix).to eq('/') }
    it { expect(subject.params).to eq({}) }
  end

  context 'with complex url' do
    let(:address) { 'http://sushi.com:815/fish?a=1' }

    it { expect(subject.port).to eq(815) }
    it { expect(subject.path_prefix).to eq('/fish') }
    it { expect(subject.params).to eq({ 'a' => '1' }) }
  end
end

RSpec.describe Faraday::Connection do
  let(:conn) { Faraday::Connection.new(url, options) }
  let(:url) { nil }
  let(:options) { {} }

  describe '.new' do
    subject { conn }

    context 'with implicit url param' do
      # Faraday::Connection.new('http://sushi.com')
      let(:url) { address }

      it_behaves_like 'initializer with url'
    end

    context 'with explicit url param' do
      # Faraday::Connection.new(url: 'http://sushi.com')
      let(:url) { { url: address } }

      it_behaves_like 'initializer with url'
    end

    context 'with custom builder' do
      let(:custom_builder) { Faraday::RackBuilder.new }
      let(:options) { { builder: custom_builder } }

      it { expect(subject.builder).to eq(custom_builder) }
    end

    context 'with custom params' do
      let(:options) { { params: { a: 1 } } }

      it { expect(subject.params).to eq({ 'a' => 1 }) }
    end

    context 'with custom params and params in url' do
      let(:url) { 'http://sushi.com/fish?a=1&b=2' }
      let(:options) { { params: { a: 3 } } }
      it { expect(subject.params).to eq({ 'a' => 3, 'b' => '2' }) }
    end

    context 'with custom headers' do
      let(:options) { { headers: { user_agent: 'Faraday' } } }

      it { expect(subject.headers['User-agent']).to eq('Faraday') }
    end
  end

  describe 'basic_auth' do
    subject { conn }

    context 'calling the #basic_auth method' do
      before { subject.basic_auth 'Aladdin', 'open sesame' }

      it { expect(subject.headers['Authorization']).to eq('Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==') }
    end

    context 'adding basic auth info to url' do
      let(:url) { 'http://Aladdin:open%20sesame@sushi.com/fish' }

      it { expect(subject.headers['Authorization']).to eq('Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==') }
    end
  end

  describe '#token_auth' do
    before { subject.token_auth('abcdef', nonce: 'abc') }

    it { expect(subject.headers['Authorization']).to eq('Token nonce="abc", token="abcdef"') }
  end

  describe '#build_exclusive_url' do
    context 'with relative path' do
      subject { conn.build_exclusive_url('sake.html') }

      it 'uses connection host as default host' do
        conn.host = 'sushi.com'
        expect(subject.host).to eq('sushi.com')
        expect(subject.scheme).to eq('http')
      end

      it do
        conn.path_prefix = '/fish'
        expect(subject.path).to eq('/fish/sake.html')
      end

      it do
        conn.path_prefix = '/'
        expect(subject.path).to eq('/sake.html')
      end

      it do
        conn.path_prefix = 'fish'
        expect(subject.path).to eq('/fish/sake.html')
      end

      it do
        conn.path_prefix = '/fish/'
        expect(subject.path).to eq('/fish/sake.html')
      end
    end

    context 'with absolute path' do
      subject { conn.build_exclusive_url('/sake.html') }

      after { expect(subject.path).to eq('/sake.html') }

      it { conn.path_prefix = '/fish' }
      it { conn.path_prefix = '/' }
      it { conn.path_prefix = 'fish' }
      it { conn.path_prefix = '/fish/' }
    end

    context 'with complete url' do
      subject { conn.build_exclusive_url('http://sushi.com/sake.html?a=1') }

      it { expect(subject.scheme).to eq('http') }
      it { expect(subject.host).to eq('sushi.com') }
      it { expect(subject.port).to eq(80) }
      it { expect(subject.path).to eq('/sake.html') }
      it { expect(subject.query).to eq('a=1') }
    end

    it 'overrides connection port for absolute url' do
      conn.port = 23
      uri = conn.build_exclusive_url('http://sushi.com')
      expect(uri.port).to eq(80)
    end

    it 'does not add ending slash given nil url' do
      conn.url_prefix = 'http://sushi.com/nigiri'
      uri = conn.build_exclusive_url
      expect(uri.path).to eq('/nigiri')
    end

    it 'does not add ending slash given empty url' do
      conn.url_prefix = 'http://sushi.com/nigiri'
      uri = conn.build_exclusive_url('')
      expect(uri.path).to eq('/nigiri')
    end

    it 'does not use connection params' do
      conn.url_prefix = 'http://sushi.com/nigiri'
      conn.params = { :a => 1 }
      expect(conn.build_exclusive_url.to_s).to eq('http://sushi.com/nigiri')
    end

    it 'allows to provide params argument' do
      conn.url_prefix = 'http://sushi.com/nigiri'
      conn.params = { :a => 1 }
      params = Faraday::Utils::ParamsHash.new
      params[:a] = 2
      uri = conn.build_exclusive_url(nil, params)
      expect(uri.to_s).to eq('http://sushi.com/nigiri?a=2')
    end

    it 'handles uri instances' do
      uri = conn.build_exclusive_url(URI('/sake.html'))
      expect(uri.path).to eq('/sake.html')
    end

    context 'with url_prefixed connection' do
      let(:url) { 'http://sushi.com/sushi/' }

      it 'parses url and changes scheme' do
        conn.scheme = 'https'
        uri = conn.build_exclusive_url('sake.html')
        expect(uri.to_s).to eq('https://sushi.com/sushi/sake.html')
      end

      it 'joins url to base with ending slash' do
        uri = conn.build_exclusive_url('sake.html')
        expect(uri.to_s).to eq('http://sushi.com/sushi/sake.html')
      end

      it 'used default base with ending slash' do
        uri = conn.build_exclusive_url
        expect(uri.to_s).to eq('http://sushi.com/sushi/')
      end

      it 'overrides base' do
        uri = conn.build_exclusive_url('/sake/')
        expect(uri.to_s).to eq('http://sushi.com/sake/')
      end
    end
  end

  describe '#build_url' do
    let(:url) { 'http://sushi.com/nigiri' }

    it 'uses params' do
      conn.params = { a: 1, b: 1 }
      expect(conn.build_url.to_s).to eq('http://sushi.com/nigiri?a=1&b=1')
    end

    it 'merges params' do
      conn.params = { a: 1, b: 1 }
      url = conn.build_url(nil, b: 2, c: 3)
      expect(url.to_s).to eq('http://sushi.com/nigiri?a=1&b=2&c=3')
    end
  end

  describe '#to_env' do
    subject { conn.build_request(:get).to_env(conn).url }

    let(:url) { 'http://sushi.com/sake.html' }
    let(:options) { { params: @params } }

    it 'parses url params into query' do
      @params = { 'a[b]' => '1 + 2'}
      expect(subject.query).to eq('a%5Bb%5D=1+%2B+2')
    end

    it 'escapes per spec' do
      @params = { 'a' => '1+2 foo~bar.-baz' }
      expect(subject.query).to eq('a=1%2B2+foo~bar.-baz')
    end

    it 'bracketizes nested params in query' do
      @params = { 'a' => { 'b' => 'c' } }
      expect(subject.query).to eq('a%5Bb%5D=c')
    end

    it 'bracketizes repeated params in query' do
      @params = { 'a' => [1, 2] }
      expect(subject.query).to eq('a%5B%5D=1&a%5B%5D=2')
    end

    it 'without braketizing repeated params in query' do
      @params = { 'a' => [1, 2] }
      conn.options.params_encoder = Faraday::FlatParamsEncoder
      expect(subject.query).to eq('a=1&a=2')
    end
  end
end