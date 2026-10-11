# frozen_string_literal: true

RSpec.describe Faraday::SSLOptions, type: :integration do
  # Generating RSA keys is slow, so the PKI and servers are shared by the group.
  before(:context) do
    @pki = Faraday::IntegrationHelpers::TestPKI.new
    server_credentials = @pki.issue('localhost', dns_names: %w[localhost secure.test])
    @server = Faraday::IntegrationHelpers::TLSServer.start(server_credentials)
    @mutual_tls_server = Faraday::IntegrationHelpers::TLSServer.start(server_credentials, client_ca: @pki)
    @ca_file = @pki.write_ca_file(File.join(Dir.mktmpdir('faraday-ssl'), 'ca.pem'))
  end

  after(:context) do
    @server.stop
    @mutual_tls_server.stop
    FileUtils.remove_entry(File.dirname(@ca_file))
  end

  let(:pki) { @pki }
  let(:server) { @server }
  let(:mutual_tls_server) { @mutual_tls_server }
  let(:ca_file) { @ca_file }

  def get_json(conn, path = '/')
    JSON.parse(conn.get(path).body)
  end

  describe 'certificate verification' do
    it 'rejects a certificate signed by an unknown CA by default' do
      conn = Faraday.new(server.url)

      expect { conn.get('/') }.to raise_error(Faraday::SSLError)
    end

    it 'accepts the certificate when verify is false' do
      conn = Faraday.new(server.url, ssl: { verify: false })

      expect(get_json(conn, '/hello')).to include('path' => '/hello')
    end

    it 'accepts the certificate when verify_mode is OpenSSL::SSL::VERIFY_NONE' do
      conn = Faraday.new(server.url, ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE })

      expect(conn.get('/').status).to eq(200)
    end

    it 'enables verification when verify is true' do
      conn = Faraday.new(server.url, ssl: { verify: true })

      expect { conn.get('/') }.to raise_error(Faraday::SSLError)
    end
  end

  describe 'custom CA' do
    it 'accepts the certificate when the CA is given as ca_file' do
      conn = Faraday.new(server.url, ssl: { ca_file: ca_file })

      expect(conn.get('/').status).to eq(200)
    end

    it 'accepts the certificate when the CA is given as cert_store' do
      conn = Faraday.new(server.url, ssl: { cert_store: pki.cert_store })

      expect(conn.get('/').status).to eq(200)
    end

    it 'rejects the certificate when ca_file contains a different CA' do
      other_ca_file = Faraday::IntegrationHelpers::TestPKI.new.write_ca_file(File.join(File.dirname(ca_file), 'other.pem'))
      conn = Faraday.new(server.url, ssl: { ca_file: other_ca_file })

      expect { conn.get('/') }.to raise_error(Faraday::SSLError)
    end
  end

  describe 'hostname verification' do
    # The certificate is valid for "localhost" but not for the 127.0.0.1 address
    let(:ip_url) { "https://127.0.0.1:#{server.port}" }

    it 'accepts a matching hostname' do
      conn = Faraday.new(server.url('localhost'), ssl: { ca_file: ca_file })

      expect(conn.get('/').status).to eq(200)
    end

    it 'rejects a mismatching hostname' do
      conn = Faraday.new(ip_url, ssl: { ca_file: ca_file })

      expect { conn.get('/') }.to raise_error(Faraday::SSLError, /127\.0\.0\.1/)
    end

    it 'accepts a mismatching hostname when verify_hostname is false' do
      conn = Faraday.new(ip_url, ssl: { ca_file: ca_file, verify_hostname: false })

      expect(conn.get('/').status).to eq(200)
    end

    it 'still verifies the CA when verify_hostname is false' do
      conn = Faraday.new(ip_url, ssl: { verify_hostname: false })

      expect { conn.get('/') }.to raise_error(Faraday::SSLError)
    end
  end

  describe 'client certificates' do
    let(:client) { pki.issue('Faraday Test Client') }

    it 'rejects clients that do not present a certificate' do
      conn = Faraday.new(mutual_tls_server.url, ssl: { ca_file: ca_file })

      expect { conn.get('/') }.to raise_error(Faraday::SSLError)
    end

    it 'accepts clients presenting a certificate signed by the expected CA' do
      conn = Faraday.new(mutual_tls_server.url,
                         ssl: { ca_file: ca_file, client_cert: client.cert, client_key: client.key })

      expect(get_json(conn)).to include('client_cert_subject' => '/CN=Faraday Test Client')
    end

    it 'rejects clients presenting a certificate signed by another CA' do
      untrusted = Faraday::IntegrationHelpers::TestPKI.new.issue('Untrusted Client')
      conn = Faraday.new(mutual_tls_server.url,
                         ssl: { ca_file: ca_file, client_cert: untrusted.cert, client_key: untrusted.key })

      expect { conn.get('/') }.to raise_error(Faraday::SSLError)
    end
  end
end
