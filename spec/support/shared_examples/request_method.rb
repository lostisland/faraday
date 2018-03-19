shared_examples 'a request method' do
  let(:query_or_body) { method_with_body?(http_method) ? :body : :query }

  it 'retrieves the response body' do
    res_body = 'test'
    request_stub.to_return(body: res_body)
    expect(conn.public_send(http_method, '/').body).to eq(res_body)
  end

  it 'handles headers with multiple values' do
    request_stub.to_return(headers: { 'Set-Cookie' => 'one, two' })
    response = conn.public_send(http_method, '/')
    expect(response.headers['set-cookie']).to eq('one, two')
  end

  it 'sends url encoded parameters' do
    # Issue with Patron and PATCH body: https://github.com/toland/patron/issues/163
    skip if described_class == Faraday::Adapter::Patron && http_method == :patch

    payload = { name: 'zack' }
    request_stub.with(Hash[query_or_body, payload])
    conn.public_send(http_method, '/', payload)
  end

  it 'sends url encoded nested parameters' do
    # Issue with Patron and PATCH body: https://github.com/toland/patron/issues/163
    skip if described_class == Faraday::Adapter::Patron && http_method == :patch

    payload = { name: { first: 'zack' } }
    request_stub.with(Hash[query_or_body, payload])
    conn.public_send(http_method, '/', payload)
  end

  it 'retrieves the response headers' do
    request_stub.to_return(headers: { 'Content-Type' => 'text/plain' })
    response = conn.public_send(http_method, '/')
    expect(response.headers['Content-Type']).to match(/text\/plain/)
    expect(response.headers['content-type']).to match(/text\/plain/)
  end

  it 'sends user agent' do
    request_stub.with(headers: { 'User-Agent' => 'Agent Faraday' })
    conn.public_send(http_method, '/', nil, user_agent: 'Agent Faraday')
  end

  it 'sends files' do
    # Can't send files on get, head and delete methods
    skip unless method_with_body?(http_method)
    # Issue with Patron and PATCH body: https://github.com/toland/patron/issues/163
    skip if described_class == Faraday::Adapter::Patron && http_method == :patch

    payload = { uploaded_file: multipart_file }
    request_stub.with(headers: { "Content-Type" => %r[\Amultipart/form-data] }) do |request|
      # WebMock does not support matching body for multipart/form-data requests yet :(
      # https://github.com/bblimke/webmock/issues/623
      request.body =~ %r[RubyMultipartPost]
    end
    conn.public_send(http_method, '/', payload)
  end

  # TODO: This needs reimplementation: see https://github.com/lostisland/faraday/issues/718
  # it 'handles open timeout responses' do
  #   request_stub.to_timeout
  #   expect { conn.public_send(http_method, '/') }.to raise_error(Faraday::Error::ConnectionFailed)
  # end

  it 'handles connection error' do
    request_stub.disable
    expect { conn.public_send(http_method, 'http://localhost:4') }.to raise_error(Faraday::Error::ConnectionFailed)
  end

  # TODO: Fix proxy tests
  # it 'handles requests with proxy' do
  #   conn_options[:proxy] = 'http://google.co.uk'
  #   # stub_request(:get, 'http://example.com/')
  #
  #   # binding.pry
  #   conn.public_send(http_method, '/')
  #   # assert_equal 'get', res.body
  #
  #   # unless self.class.ssl_mode?
  #   #   # proxy can't append "Via" header for HTTPS responses
  #   #   assert_match(/:#{proxy_uri.port}$/, res['via'])
  #   # end
  # end
  #
  # it 'handles proxy failures' do
  #   proxy_uri = URI(ENV['LIVE_PROXY'])
  #   proxy_uri.password = 'WRONG'
  #   conn = create_connection(:proxy => proxy_uri)
  #
  #   err = assert_raises Faraday::Error::ConnectionFailed do
  #     conn.get '/echo'
  #   end
  #
  #   unless self.class.ssl_mode? && (self.class.jruby? ||
  #       adapter == :em_http || adapter == :em_synchrony)
  #     # JRuby raises "End of file reached" which cannot be distinguished from a 407
  #     # EM raises "connection closed by server" due to https://github.com/igrigorik/em-socksify/pull/19
  #     assert_equal %{407 "Proxy Authentication Required "}, err.message
  #   end
  # end

  on_feature :reason_phrase_parse do
    it 'parses the reason phrase' do
      request_stub.to_return(status: [200, 'OK'])
      response = conn.public_send(http_method, '/')
      expect(response.reason_phrase).to eq('OK')
    end
  end
end