shared_examples 'an adapter' do |**options|
  let(:adapter) { described_class.name.split('::').last }

  let(:conn_options) { { headers: { 'X-Faraday-Adapter' => adapter } }.merge(options[:conn_options] || {}) }

  let(:adapter_options) do
    return [] unless options[:adapter_options]
    if options[:adapter_options].is_a?(Array)
      options[:adapter_options]
    else
      [options[:adapter_options]]
    end
  end

  let(:protocol) { ssl_mode? ? 'https' : 'http' }
  let(:remote) { "#{protocol}://example.com" }

  let(:conn) do
    conn_options[:ssl]           ||= {}
    conn_options[:ssl][:ca_file] ||= ENV['SSL_FILE']

    Faraday::Connection.new(remote, conn_options) do |conn|
      conn.request :multipart
      conn.request :url_encoded
      conn.response :raise_error
      conn.adapter described_class, *adapter_options
    end
  end

  let(:request_stub) { stub_request(http_method, remote) }

  after do
    expect(request_stub).to have_been_requested
  end

  describe '#get' do
    let(:http_method) { :get }

    it 'retrieves the response body' do
      res_body = 'test'
      request_stub.to_return(body: res_body)
      expect(conn.get('/').body).to eq(res_body)
    end

    it 'sends url encoded parameters' do
      query = { name: 'zack' }
      request_stub.with(query: query)
      conn.get('/', query)
    end

    it 'retrieves the response headers' do
      request_stub.to_return(headers: { 'Content-Type' => 'text/plain' })
      response = conn.get('/')
      expect(response.headers['Content-Type']).to match(/text\/plain/)
      expect(response.headers['content-type']).to match(/text\/plain/)
    end

    it 'handles headers with multiple values' do
      request_stub.to_return(headers: { 'Set-Cookie' => 'one, two' })
      response = conn.get('/')
      expect(response.headers['set-cookie']).to eq('one, two')
    end

    on_feature :body_on_get do
      it 'with body' do
        body = { bodyrock: 'true' }
        request_stub.with(body: body)
        conn.get('/') do |req|
          req.body = body
        end
      end
    end

    it 'sends user agent' do
      request_stub.with(headers: { 'User-Agent' => 'Agent Faraday' })
      conn.get('/', nil, user_agent: 'Agent Faraday')
    end

    on_feature :reason_phrase_parse do
      it 'parses the reason phrase' do
        request_stub.to_return(status: [200, 'OK'])
        response = conn.get('/')
        expect(response.reason_phrase).to eq('OK')
      end
    end
  end
end