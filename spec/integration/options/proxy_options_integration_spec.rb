# frozen_string_literal: true

RSpec.describe Faraday::ProxyOptions, type: :integration do
  # Generating RSA keys is slow, so the PKI and HTTPS server are shared by the group.
  before(:context) do
    @pki = Faraday::IntegrationHelpers::TestPKI.new
    credentials = @pki.issue('localhost', dns_names: %w[localhost secure.test])
    @tls_server = Faraday::IntegrationHelpers::TLSServer.start(credentials)
    @ca_file = @pki.write_ca_file(File.join(Dir.mktmpdir('faraday-proxy'), 'ca.pem'))
  end

  after(:context) do
    @tls_server.stop
    FileUtils.remove_entry(File.dirname(@ca_file))
  end

  let(:tls_server) { @tls_server }
  let(:ca_file) { @ca_file }
  let(:httpbin) { URI(Faraday::IntegrationHelpers::HTTPBIN_URL) }

  # Fake host names are routed to the real test servers by the proxy. This is
  # needed to test proxies configured via the environment, because Ruby never
  # proxies requests to loopback hosts in that case.
  let(:hosts) do
    {
      'target.test:80' => [httpbin.host, httpbin.port],
      'secure.test:443' => ['127.0.0.1', tls_server.port]
    }
  end
  let(:credentials) { nil }
  let!(:proxy) { Faraday::IntegrationHelpers::ProxyServer.start(credentials: credentials, hosts: hosts) }

  after { proxy.stop }

  def proxied_requests
    proxy.requests.map { |request| [request.http_method, request.target] }
  end

  describe 'HTTP requests' do
    let(:target) { URI.join(httpbin, '/get').to_s }

    it 'does not use the proxy when none is configured' do
      response = httpbin_connection.get('/get')

      expect(response.status).to eq(200)
      expect(proxy.requests).to be_empty
    end

    it 'routes requests through a proxy given as a URL string' do
      response = httpbin_connection(proxy: proxy.url).get('/get', foo: 'bar')

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['args']).to eq('foo' => 'bar')
      expect(proxied_requests).to eq([['GET', "#{target}?foo=bar"]])
    end

    it 'routes requests through a proxy given as a hash' do
      conn = httpbin_connection(proxy: { uri: proxy.url })

      expect(conn.get('/get').status).to eq(200)
      expect(proxied_requests).to eq([['GET', target]])
    end

    it 'routes requests through a proxy given as a URI' do
      conn = httpbin_connection(proxy: URI(proxy.url))

      expect(conn.get('/get').status).to eq(200)
      expect(proxied_requests).to eq([['GET', target]])
    end

    it 'exposes the parsed proxy options' do
      conn = httpbin_connection(proxy: proxy.url)

      expect(conn.proxy).to be_a(described_class)
      expect(conn.proxy.uri).to eq(URI(proxy.url))
      expect(conn.proxy.host).to eq('127.0.0.1')
      expect(conn.proxy.port).to eq(proxy.port)
    end

    it 'applies a proxy set after the connection is built' do
      conn = httpbin_connection
      conn.proxy = proxy.url

      expect(conn.get('/get').status).to eq(200)
      expect(proxied_requests).to eq([['GET', target]])
    end

    it 'stops using the proxy once it is unset' do
      conn = httpbin_connection(proxy: proxy.url)
      conn.proxy = nil

      expect(conn.get('/get').status).to eq(200)
      expect(proxy.requests).to be_empty
    end

    it 'forwards request bodies and headers through the proxy' do
      conn = httpbin_connection(proxy: proxy.url, headers: { 'X-Test' => 'yes' })

      response = conn.post('/post', 'hello=world')

      json = JSON.parse(response.body)
      expect(json['form']).to eq('hello' => 'world')
      expect(json['headers']).to include('X-Test' => 'yes')
      expect(proxied_requests).to eq([['POST', URI.join(httpbin, '/post').to_s]])
    end
  end

  describe 'HTTPS requests' do
    let(:conn) { Faraday.new(tls_server.url, proxy: proxy.url, ssl: { ca_file: ca_file }) }

    it 'tunnels through the proxy with CONNECT' do
      response = conn.get('/hello')

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to include('path' => '/hello')
      expect(proxied_requests).to eq([['CONNECT', "localhost:#{tls_server.port}"]])
    end

    it 'verifies the certificate of the target, not of the proxy' do
      conn = Faraday.new(tls_server.url, proxy: proxy.url)

      expect { conn.get('/') }.to raise_error(Faraday::SSLError)
      expect(proxied_requests).to eq([['CONNECT', "localhost:#{tls_server.port}"]])
    end
  end

  describe 'proxy authentication' do
    let(:credentials) { ['user', 'p@ss word'] }
    let(:proxy_with_credentials) { proxy.url.sub('http://', 'http://user:p%40ss%20word@') }

    it 'authenticates with credentials embedded in the proxy URL' do
      conn = httpbin_connection(proxy: proxy_with_credentials)

      expect(conn.get('/get').status).to eq(200)
      expect(conn.proxy.user).to eq('user')
      expect(conn.proxy.password).to eq('p@ss word')
    end

    it 'authenticates with the user and password options' do
      conn = httpbin_connection(proxy: { uri: proxy.url, user: 'user', password: 'p@ss word' })

      expect(conn.get('/get').status).to eq(200)
    end

    it 'receives a 407 when the credentials are wrong' do
      conn = httpbin_connection(proxy: { uri: proxy.url, user: 'user', password: 'wrong' })

      expect(conn.get('/get').status).to eq(407)
    end

    it 'receives a 407 when no credentials are given' do
      conn = httpbin_connection(proxy: proxy.url)

      expect(conn.get('/get').status).to eq(407)
    end

    it 'raises ProxyAuthError for a 407 when using the raise_error middleware' do
      conn = httpbin_connection(proxy: proxy.url) { |f| f.response :raise_error }

      expect { conn.get('/get') }.to raise_error(Faraday::ProxyAuthError)
    end

    it 'authenticates CONNECT tunnels' do
      conn = Faraday.new(tls_server.url, proxy: proxy_with_credentials, ssl: { ca_file: ca_file })

      expect(conn.get('/').status).to eq(200)
      expect(proxy.requests.first.http_method).to eq('CONNECT')
    end

    it 'refuses to open a tunnel without credentials' do
      conn = Faraday.new(tls_server.url, proxy: proxy.url, ssl: { ca_file: ca_file })

      expect { conn.get('/') }.to raise_error(Faraday::ConnectionFailed, /407/)
    end
  end

  describe 'environment variables' do
    it 'uses http_proxy for HTTP requests' do
      with_env('http_proxy' => proxy.url) do
        response = Faraday.new('http://target.test').get('/get')

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['headers']).to include('Host' => 'target.test')
        expect(proxied_requests).to eq([['GET', 'http://target.test/get']])
      end
    end

    it 'uses https_proxy for HTTPS requests' do
      with_env('https_proxy' => proxy.url) do
        conn = Faraday.new('https://secure.test', ssl: { ca_file: ca_file })

        expect(conn.get('/').status).to eq(200)
        expect(proxied_requests).to eq([['CONNECT', 'secure.test:443']])
      end
    end

    it 'does not use http_proxy for HTTPS requests' do
      with_env('http_proxy' => proxy.url) do
        conn = Faraday.new(tls_server.url, ssl: { ca_file: ca_file })

        expect(conn.get('/').status).to eq(200)
        expect(proxy.requests).to be_empty
      end
    end

    it 'bypasses the proxy for hosts listed in no_proxy' do
      with_env('http_proxy' => proxy.url, 'no_proxy' => "target.test,#{httpbin.host}") do
        expect(Faraday.new('http://target.test').proxy).to be_nil

        conn = httpbin_connection
        expect(conn.proxy).to be_nil
        expect(conn.get('/get').status).to eq(200)
        expect(proxy.requests).to be_empty
      end
    end

    it 'gives precedence to an explicit proxy over the environment' do
      other_proxy = Faraday::IntegrationHelpers::ProxyServer.start(hosts: hosts)

      with_env('http_proxy' => other_proxy.url) do
        expect(Faraday.new('http://target.test', proxy: proxy.url).get('/get').status).to eq(200)
        expect(proxied_requests).to eq([['GET', 'http://target.test/get']])
        expect(other_proxy.requests).to be_empty
      end
    ensure
      other_proxy.stop
    end

    it 'ignores the environment when Faraday.ignore_env_proxy is set' do
      with_env('http_proxy' => proxy.url) do
        with_env_proxy_disabled do
          expect(Faraday.new('http://target.test').proxy).to be_nil
        end
      end
    end
  end
end
