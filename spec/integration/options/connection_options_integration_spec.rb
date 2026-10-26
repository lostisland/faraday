# frozen_string_literal: true

RSpec.describe Faraday::ConnectionOptions do
  # Generating RSA keys is slow, so the PKI and HTTPS server are shared by the group.
  before(:context) do
    @pki = Faraday::IntegrationHelpers::TestPKI.new
    @tls_server = Faraday::IntegrationHelpers::TLSServer.start(@pki.issue('localhost', dns_names: %w[localhost]))
    @ca_file = @pki.write_ca_file(File.join(Dir.mktmpdir('faraday-connection'), 'ca.pem'))
  end

  after(:context) do
    @tls_server.stop
    FileUtils.remove_entry(File.dirname(@ca_file))
  end

  let(:tls_server) { @tls_server }
  let(:ca_file) { @ca_file }
  let(:httpbin_url) { Faraday::IntegrationHelpers::HTTPBIN_URL }

  def json(response)
    JSON.parse(response.body)
  end

  describe 'building a connection' do
    it 'accepts the base URL and an options hash' do
      conn = Faraday.new(httpbin_url, headers: { 'X-Test' => 'a' }, params: { q: '1' })

      body = json(conn.get('/get'))
      expect(body['headers']).to include('X-Test' => 'a')
      expect(body['args']).to eq('q' => '1')
    end

    it 'accepts a single options hash containing the URL' do
      conn = Faraday.new(url: httpbin_url, headers: { 'X-Test' => 'a' })

      expect(json(conn.get('/get'))['headers']).to include('X-Test' => 'a')
    end

    it 'accepts a ConnectionOptions instance' do
      options = described_class.from(url: httpbin_url, params: { q: '1' }, request: { timeout: 5 })
      conn = Faraday.new(options)

      expect(conn.options.timeout).to eq(5)
      expect(json(conn.get('/get'))['args']).to eq('q' => '1')
    end

    it 'merges a hash given as URL with the options' do
      conn = Faraday.new({ url: httpbin_url, headers: { 'X-First' => '1' } }, headers: { 'X-Second' => '2' })

      expect(json(conn.get('/get'))['headers']).to include('X-First' => '1', 'X-Second' => '2')
    end

    it 'coerces raw hashes into nested options objects' do
      conn = Faraday.new(httpbin_url, request: { timeout: 7, open_timeout: 3 }, ssl: { verify: false })

      expect(conn.options).to be_a(Faraday::RequestOptions)
      expect(conn.options.timeout).to eq(7)
      expect(conn.options.open_timeout).to eq(3)
      expect(conn.ssl).to be_a(Faraday::SSLOptions)
      expect(conn.ssl.verify).to be(false)
      expect(conn.get('/get').status).to eq(200)
    end

    it 'applies the options set in Faraday.default_connection_options' do
      original = Faraday.default_connection_options
      Faraday.default_connection_options = { headers: { 'X-Default' => 'yes' }, request: { timeout: 9 } }

      conn = Faraday.new(httpbin_url, headers: { 'X-Own' => 'mine' })

      expect(conn.options.timeout).to eq(9)
      expect(json(conn.get('/get'))['headers']).to include('X-Default' => 'yes', 'X-Own' => 'mine')
    ensure
      Faraday.default_connection_options = original
    end

    it 'lets the connection options override the default connection options' do
      original = Faraday.default_connection_options
      Faraday.default_connection_options = { headers: { 'X-Default' => 'yes' }, request: { timeout: 9 } }

      conn = Faraday.new(httpbin_url, headers: { 'X-Default' => 'no' }, request: { timeout: 2 })

      expect(conn.options.timeout).to eq(2)
      expect(json(conn.get('/get'))['headers']).to include('X-Default' => 'no')
    ensure
      Faraday.default_connection_options = original
    end
  end

  describe 'headers' do
    it 'sends the connection headers with every request' do
      conn = httpbin_connection(headers: { 'X-Test' => 'a' })

      2.times { expect(json(conn.get('/get'))['headers']).to include('X-Test' => 'a') }
    end

    it 'merges request headers over the connection headers' do
      conn = httpbin_connection(headers: { 'X-Keep' => 'kept', 'X-Override' => 'connection' })

      response = conn.get('/get') do |req|
        req.headers['X-Override'] = 'request'
        req.headers['X-Added'] = 'added'
      end

      expect(json(response)['headers']).to include('X-Keep' => 'kept', 'X-Override' => 'request', 'X-Added' => 'added')
    end

    it 'does not leak request headers into the connection' do
      conn = httpbin_connection(headers: { 'X-Test' => 'a' })

      conn.get('/get') { |req| req.headers['X-Test'] = 'b' }

      expect(conn.headers['X-Test']).to eq('a')
      expect(json(conn.get('/get'))['headers']).to include('X-Test' => 'a')
    end

    it 'treats header names case-insensitively' do
      conn = httpbin_connection(headers: { 'x-test' => 'a' })

      response = conn.get('/get') { |req| req.headers['X-TEST'] = 'b' }

      expect(json(response)['headers']).to include('X-Test' => 'b')
    end

    it 'sends headers added after the connection is built' do
      conn = httpbin_connection
      conn.headers['X-Late'] = 'late'
      conn.headers.update('X-Bulk' => 'bulk')

      expect(json(conn.get('/get'))['headers']).to include('X-Late' => 'late', 'X-Bulk' => 'bulk')
    end
  end

  describe 'params' do
    it 'sends the connection params with every request' do
      conn = httpbin_connection(params: { token: 'abc' })

      2.times { expect(json(conn.get('/get'))['args']).to eq('token' => 'abc') }
    end

    it 'merges request params over the connection params' do
      conn = httpbin_connection(params: { keep: 'kept', override: 'connection' })

      response = conn.get('/get', override: 'request', added: 'added')

      expect(json(response)['args']).to eq('keep' => 'kept', 'override' => 'request', 'added' => 'added')
    end

    it 'does not leak request params into the connection' do
      conn = httpbin_connection(params: { token: 'abc' })

      conn.get('/get', extra: '1')

      expect(conn.params).to eq('token' => 'abc')
    end

    it 'merges the query string of the base URL with the connection params' do
      conn = Faraday.new("#{httpbin_url}/get?from_url=1", params: { from_options: '2' })

      expect(json(conn.get)['args']).to eq('from_url' => '1', 'from_options' => '2')
    end

    it 'encodes the params with the params_encoder of the request options' do
      conn = httpbin_connection(params: { tags: %w[a b] }, request: { params_encoder: Faraday::FlatParamsEncoder })

      expect(json(conn.get('/get'))['args']).to eq('tags' => %w[a b])
    end
  end

  describe 'url' do
    it 'resolves relative paths against the path of the base URL' do
      conn = Faraday.new("#{httpbin_url}/anything/base")

      expect(json(conn.get('child'))['url']).to eq("#{httpbin_url}/anything/base/child")
    end

    it 'resolves absolute paths against the host of the base URL' do
      conn = Faraday.new("#{httpbin_url}/anything/base")

      expect(json(conn.get('/get'))['url']).to eq("#{httpbin_url}/get")
    end

    it 'sends requests to an absolute URL regardless of the base URL' do
      conn = Faraday.new('http://unreachable.invalid')

      expect(conn.get("#{httpbin_url}/get").status).to eq(200)
    end
  end

  describe 'request options' do
    it 'applies the connection timeout to every request' do
      conn = httpbin_connection(request: { timeout: 1 })

      expect { conn.get('/delay/3') }.to raise_error(Faraday::TimeoutError)
      expect { conn.get('/delay/3') }.to raise_error(Faraday::TimeoutError)
    end

    it 'lets a request override the connection timeout without changing it' do
      conn = httpbin_connection(request: { timeout: 1 })

      expect(conn.get('/delay/2') { |req| req.options.timeout = 5 }.status).to eq(200)
      expect(conn.options.timeout).to eq(1)
      expect { conn.get('/delay/3') }.to raise_error(Faraday::TimeoutError)
    end

    it 'applies request options changed after the connection is built' do
      conn = httpbin_connection
      conn.options.timeout = 1

      expect { conn.get('/delay/3') }.to raise_error(Faraday::TimeoutError)
    end
  end

  describe 'ssl options' do
    it 'applies the nested SSL options to HTTPS requests' do
      conn = Faraday.new(tls_server.url, ssl: { ca_file: ca_file })

      expect(json(conn.get('/hello'))).to include('path' => '/hello')
    end

    it 'applies SSL options changed after the connection is built' do
      conn = Faraday.new(tls_server.url)
      expect { conn.get('/') }.to raise_error(Faraday::SSLError)

      conn.ssl.ca_file = ca_file

      expect(conn.get('/').status).to eq(200)
    end

    it 'does not affect plain HTTP requests' do
      conn = httpbin_connection(ssl: { ca_file: '/does/not/exist.pem', verify: true })

      expect(conn.get('/get').status).to eq(200)
    end
  end

  describe 'middleware stack' do
    let(:recorder) do
      Class.new(Faraday::Middleware) do
        class << self
          attr_accessor :events
        end

        def initialize(app, name = 'recorder')
          super(app)
          @name = name
        end

        def on_request(env)
          self.class.events << [:request, @name, env.url.path]
        end

        def on_complete(env)
          self.class.events << [:response, @name, env.status]
        end
      end
    end

    before { recorder.events = [] }

    it 'sends form-encoded bodies with the url_encoded middleware by default' do
      response = httpbin_connection.post('/post', name: 'Ruby', tags: %w[a b])

      body = json(response)
      expect(body['headers']['Content-Type']).to eq('application/x-www-form-urlencoded')
      expect(body['form']).to eq('name' => 'Ruby', 'tags[]' => %w[a b])
    end

    it 'runs middleware in order on the way out and in reverse on the way back' do
      conn = httpbin_connection do |f|
        f.use recorder, 'first'
        f.use recorder, 'second'
      end

      conn.get('/get')

      expect(recorder.events).to eq(
        [[:request, 'first', '/get'], [:request, 'second', '/get'],
         [:response, 'second', 200], [:response, 'first', 200]]
      )
    end

    it 'lets middleware modify the request' do
      add_header = Class.new(Faraday::Middleware) do
        def on_request(env)
          env.request_headers['X-From-Middleware'] = 'yes'
          env.url.query = 'added=by-middleware'
        end
      end
      conn = httpbin_connection { |f| f.use add_header }

      body = json(conn.get('/get'))

      expect(body['headers']).to include('X-From-Middleware' => 'yes')
      expect(body['args']).to eq('added' => 'by-middleware')
    end

    it 'lets middleware modify the response' do
      shout = Class.new(Faraday::Middleware) do
        def on_complete(env)
          env.body = env.body.upcase
          env.response_headers['X-Shouted'] = 'true'
        end
      end
      conn = httpbin_connection { |f| f.use shout }

      response = conn.get('/get', word: 'quiet')

      expect(response.body).to include('"WORD": "QUIET"')
      expect(response.headers['X-Shouted']).to eq('true')
    end

    it 'encodes and parses JSON with the json middleware' do
      conn = httpbin_connection do |f|
        f.request :json
        f.response :json
      end

      response = conn.post('/post', { name: 'Ruby', nested: { list: [1, 2] } })

      expect(response.body['json']).to eq('name' => 'Ruby', 'nested' => { 'list' => [1, 2] })
      expect(response.body['headers']['Content-Type']).to eq('application/json')
    end

    it 'sends credentials with the authorization middleware' do
      conn = httpbin_connection { |f| f.request :authorization, :basic, 'user', 'secret' }

      response = conn.get('/basic-auth/user/secret')

      expect(response.status).to eq(200)
      expect(json(response)).to eq('authenticated' => true, 'user' => 'user')
    end

    it 'raises on error statuses with the raise_error middleware' do
      conn = httpbin_connection { |f| f.response :raise_error }

      expect { conn.get('/status/404') }.to raise_error(Faraday::ResourceNotFound)
      expect { conn.get('/status/500') }.to raise_error(Faraday::ServerError)
    end

    it 'lets middleware access the connection options through the env' do
      captured = nil
      capture = Class.new(Faraday::Middleware) do
        define_method(:on_request) { |env| captured = [env.request.timeout, env.ssl.verify, env.request_headers['X-Test']] }
      end
      conn = httpbin_connection(request: { timeout: 4 }, ssl: { verify: false }, headers: { 'X-Test' => 'a' }) do |f|
        f.use capture
      end

      conn.get('/get')

      expect(captured).to eq([4, false, 'a'])
    end

    it 'supports a custom builder given through the options' do
      builder = Faraday::RackBuilder.new { |f| f.request :json }
      conn = Faraday.new(httpbin_url, builder: builder)

      response = conn.post('/post', { a: 1 })

      expect(json(response)['json']).to eq('a' => 1)
    end

    it 'supports a custom builder_class' do
      builder_class = Class.new(Faraday::RackBuilder)
      conn = Faraday.new(httpbin_url, builder_class: builder_class)

      expect(conn.builder).to be_a(builder_class)
      expect(conn.get('/get').status).to eq(200)
    end

    it 'supports middleware added after the connection is built' do
      conn = httpbin_connection
      conn.response :json

      expect(conn.get('/get').body).to include('url' => "#{httpbin_url}/get")
    end
  end

  describe 'duplicating a connection' do
    it 'keeps the options and does not share changes with the original' do
      conn = httpbin_connection(headers: { 'X-Test' => 'a' }, params: { q: '1' }, request: { timeout: 5 })
      copy = conn.dup
      copy.headers['X-Test'] = 'b'
      copy.params['q'] = '2'
      copy.options.timeout = 1

      expect(json(conn.get('/get'))).to include('args' => { 'q' => '1' })
      expect(conn.headers['X-Test']).to eq('a')
      expect(conn.options.timeout).to eq(5)
      expect(json(copy.get('/get'))['args']).to eq('q' => '2')
    end
  end
end
