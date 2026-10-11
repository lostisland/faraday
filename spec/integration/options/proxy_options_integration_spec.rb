# frozen_string_literal: true

# The proxies run as service containers (see .github/workflows/integration-tests.yml).
# Specs check that a request went through a proxy by the address its target saw:
# httpbin echoes it as `origin`, TLSServer as `remote_ip`.
RSpec.describe Faraday::ProxyOptions, type: :integration do
  # Generating RSA keys is slow, so the PKI and HTTPS server are shared by the group.
  # The HTTPS server is addressed by the hostname of the job container, which the
  # proxies can reach. It is not a loopback address either, which matters because
  # Ruby never proxies requests to loopback hosts when the proxy comes from the environment.
  before(:context) do
    @hostname = Socket.gethostname
    @pki = Faraday::IntegrationHelpers::TestPKI.new
    credentials = @pki.issue(@hostname, dns_names: [@hostname])
    @tls_server = Faraday::IntegrationHelpers::TLSServer.start(credentials, host: '0.0.0.0')
    @ca_file = @pki.write_ca_file(File.join(Dir.mktmpdir('faraday-proxy'), 'ca.pem'))
  end

  after(:context) do
    @tls_server.stop
    FileUtils.remove_entry(File.dirname(@ca_file))
  end

  let(:tls_url) { @tls_server.url(@hostname) }
  let(:ca_file) { @ca_file }
  let(:own_ip) { IPSocket.getaddress(@hostname) }
  let(:httpbin) { URI(Faraday::IntegrationHelpers::HTTPBIN_URL) }
  let(:proxy_url) { Faraday::IntegrationHelpers::PROXY_URL }
  let(:proxy_ip) { ip_of(proxy_url) }
  let(:auth_proxy_url) { Faraday::IntegrationHelpers::AUTH_PROXY_URL }

  def ip_of(url)
    IPSocket.getaddress(URI(url).host)
  end

  def echoed(response, field)
    JSON.parse(response.body)[field]
  end

  describe 'HTTP requests' do
    it 'does not use the proxy when none is configured' do
      response = httpbin_connection.get('/get')

      expect(response.status).to eq(200)
      expect(echoed(response, 'origin')).to eq(own_ip)
    end

    it 'routes requests through a proxy given as a URL string' do
      response = httpbin_connection(proxy: proxy_url).get('/get', foo: 'bar')

      expect(response.status).to eq(200)
      expect(echoed(response, 'args')).to eq('foo' => 'bar')
      expect(echoed(response, 'origin')).to eq(proxy_ip)
    end

    it 'routes requests through a proxy given as a hash' do
      response = httpbin_connection(proxy: { uri: proxy_url }).get('/get')

      expect(response.status).to eq(200)
      expect(echoed(response, 'origin')).to eq(proxy_ip)
    end

    it 'routes requests through a proxy given as a URI' do
      response = httpbin_connection(proxy: URI(proxy_url)).get('/get')

      expect(response.status).to eq(200)
      expect(echoed(response, 'origin')).to eq(proxy_ip)
    end

    it 'exposes the parsed proxy options' do
      conn = httpbin_connection(proxy: proxy_url)

      expect(conn.proxy).to be_a(described_class)
      expect(conn.proxy.uri).to eq(URI(proxy_url))
      expect(conn.proxy.host).to eq(URI(proxy_url).host)
      expect(conn.proxy.port).to eq(URI(proxy_url).port)
    end

    it 'applies a proxy set after the connection is built' do
      conn = httpbin_connection
      conn.proxy = proxy_url

      expect(echoed(conn.get('/get'), 'origin')).to eq(proxy_ip)
    end

    it 'stops using the proxy once it is unset' do
      conn = httpbin_connection(proxy: proxy_url)
      conn.proxy = nil

      expect(echoed(conn.get('/get'), 'origin')).to eq(own_ip)
    end

    it 'forwards request bodies and headers through the proxy' do
      conn = httpbin_connection(proxy: proxy_url, headers: { 'X-Test' => 'yes' })

      json = JSON.parse(conn.post('/post', 'hello=world').body)
      expect(json['form']).to eq('hello' => 'world')
      expect(json['headers']).to include('X-Test' => 'yes')
      expect(json['origin']).to eq(proxy_ip)
    end
  end

  describe 'HTTPS requests' do
    it 'tunnels through the proxy with CONNECT' do
      response = Faraday.new(tls_url, proxy: proxy_url, ssl: { ca_file: ca_file }).get('/hello')

      expect(response.status).to eq(200)
      expect(echoed(response, 'path')).to eq('/hello')
      expect(echoed(response, 'remote_ip')).to eq(proxy_ip)
    end

    it 'verifies the certificate of the target, not of the proxy' do
      conn = Faraday.new(tls_url, proxy: proxy_url)

      expect { conn.get('/') }.to raise_error(Faraday::SSLError)
    end
  end

  describe 'proxy authentication' do
    # Must match the auth-proxy service in .github/workflows/integration-tests.yml
    let(:password) { 'p@ss word' }
    let(:proxy_with_credentials) { auth_proxy_url.sub('http://', 'http://user:p%40ss%20word@') }

    it 'authenticates with credentials embedded in the proxy URL' do
      conn = httpbin_connection(proxy: proxy_with_credentials)

      response = conn.get('/get')
      expect(response.status).to eq(200)
      expect(echoed(response, 'origin')).to eq(ip_of(auth_proxy_url))
      expect(conn.proxy.user).to eq('user')
      expect(conn.proxy.password).to eq(password)
    end

    it 'authenticates with the user and password options' do
      conn = httpbin_connection(proxy: { uri: auth_proxy_url, user: 'user', password: password })

      expect(conn.get('/get').status).to eq(200)
    end

    it 'receives a 407 when the credentials are wrong' do
      conn = httpbin_connection(proxy: { uri: auth_proxy_url, user: 'user', password: 'wrong' })

      expect(conn.get('/get').status).to eq(407)
    end

    it 'receives a 407 when no credentials are given' do
      conn = httpbin_connection(proxy: auth_proxy_url)

      expect(conn.get('/get').status).to eq(407)
    end

    it 'raises ProxyAuthError for a 407 when using the raise_error middleware' do
      conn = httpbin_connection(proxy: auth_proxy_url) { |f| f.response :raise_error }

      expect { conn.get('/get') }.to raise_error(Faraday::ProxyAuthError)
    end

    it 'authenticates CONNECT tunnels' do
      conn = Faraday.new(tls_url, proxy: proxy_with_credentials, ssl: { ca_file: ca_file })

      response = conn.get('/')
      expect(response.status).to eq(200)
      expect(echoed(response, 'remote_ip')).to eq(ip_of(auth_proxy_url))
    end

    it 'refuses to open a tunnel without credentials' do
      conn = Faraday.new(tls_url, proxy: auth_proxy_url, ssl: { ca_file: ca_file })

      expect { conn.get('/') }.to raise_error(Faraday::ConnectionFailed, /407/)
    end
  end

  describe 'environment variables' do
    it 'uses http_proxy for HTTP requests' do
      with_env('http_proxy' => proxy_url) do
        response = Faraday.new(httpbin.to_s).get('/get')

        expect(response.status).to eq(200)
        expect(echoed(response, 'origin')).to eq(proxy_ip)
      end
    end

    it 'uses https_proxy for HTTPS requests' do
      with_env('https_proxy' => proxy_url) do
        response = Faraday.new(tls_url, ssl: { ca_file: ca_file }).get('/')

        expect(response.status).to eq(200)
        expect(echoed(response, 'remote_ip')).to eq(proxy_ip)
      end
    end

    it 'does not use http_proxy for HTTPS requests' do
      with_env('http_proxy' => proxy_url) do
        response = Faraday.new(tls_url, ssl: { ca_file: ca_file }).get('/')

        expect(response.status).to eq(200)
        expect(echoed(response, 'remote_ip')).to eq(own_ip)
      end
    end

    it 'bypasses the proxy for hosts listed in no_proxy' do
      with_env('http_proxy' => proxy_url, 'no_proxy' => httpbin.host) do
        conn = httpbin_connection

        expect(conn.proxy).to be_nil
        expect(echoed(conn.get('/get'), 'origin')).to eq(own_ip)
      end
    end

    # The proxy from the environment requires credentials, so it would answer 407
    it 'gives precedence to an explicit proxy over the environment' do
      with_env('http_proxy' => auth_proxy_url) do
        response = Faraday.new(httpbin.to_s, proxy: proxy_url).get('/get')

        expect(response.status).to eq(200)
        expect(echoed(response, 'origin')).to eq(proxy_ip)
      end
    end

    it 'ignores the environment when Faraday.ignore_env_proxy is set' do
      with_env('http_proxy' => proxy_url) do
        with_env_proxy_disabled do
          expect(Faraday.new(httpbin.to_s).proxy).to be_nil
        end
      end
    end
  end
end
