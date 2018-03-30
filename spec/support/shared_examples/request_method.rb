shared_examples 'a request method' do |http_method|
  let(:query_or_body) { method_with_body?(http_method) ? :body : :query }
  let(:response) { conn.public_send(http_method, '/') }

  it 'retrieves the response body' do
    res_body = 'test'
    request_stub.to_return(body: res_body)
    expect(conn.public_send(http_method, '/').body).to eq(res_body)
  end

  it 'handles headers with multiple values' do
    request_stub.to_return(headers: { 'Set-Cookie' => 'one, two' })
    expect(response.headers['set-cookie']).to eq('one, two')
  end

  it 'retrieves the response headers' do
    request_stub.to_return(headers: { 'Content-Type' => 'text/plain' })
    expect(response.headers['Content-Type']).to match(/text\/plain/)
    expect(response.headers['content-type']).to match(/text\/plain/)
  end

  it 'sends user agent' do
    request_stub.with(headers: { 'User-Agent' => 'Agent Faraday' })
    conn.public_send(http_method, '/', nil, user_agent: 'Agent Faraday')
  end

  it 'represents empty body response as blank string' do
    expect(response.body).to eq('')
  end

  it 'handles connection error' do
    request_stub.disable
    expect { conn.public_send(http_method, 'http://localhost:4') }.to raise_error(Faraday::Error::ConnectionFailed)
  end

  # Issue with Patron and PATCH body: https://github.com/toland/patron/issues/163
  unless described_class == Faraday::Adapter::Patron && http_method == :patch
    it 'sends url encoded parameters' do
      payload = { name: 'zack' }
      request_stub.with(Hash[query_or_body, payload])
      conn.public_send(http_method, '/', payload)
    end

    it 'sends url encoded nested parameters' do
      payload = { name: { first: 'zack' } }
      request_stub.with(Hash[query_or_body, payload])
      conn.public_send(http_method, '/', payload)
    end

    # Can't send files on get, head and delete methods
    if method_with_body?(http_method)
      it 'sends files' do
        payload = { uploaded_file: multipart_file }
        request_stub.with(headers: { "Content-Type" => %r[\Amultipart/form-data] }) do |request|
          # WebMock does not support matching body for multipart/form-data requests yet :(
          # https://github.com/bblimke/webmock/issues/623
          request.body =~ %r[RubyMultipartPost]
        end
        conn.public_send(http_method, '/', payload)
      end
    end
  end

  on_feature :reason_phrase_parse do
    it 'parses the reason phrase' do
      request_stub.to_return(status: [200, 'OK'])
      expect(response.reason_phrase).to eq('OK')
    end
  end

  on_feature :compression do
    # Accept-Encoding header not sent for HEAD requests as body is not expected in the response.
    unless http_method == :head
      it 'handles gzip compression' do
        request_stub.with(headers: { 'Accept-Encoding' => %r[\bgzip\b] })
        conn.public_send(http_method, '/')
      end

      it 'handles deflate compression' do
        request_stub.with(headers: { 'Accept-Encoding' => %r[\bdeflate\b] })
        conn.public_send(http_method, '/')
      end
    end
  end

  on_feature :streaming do
    describe 'streaming' do
      let(:streamed) { [] }

      context 'when response is empty' do
        it do
          conn.public_send(http_method, '/') do |req|
            req.options.on_data = Proc.new { |*args| streamed << args }
          end

          expect(streamed).to eq([["", 0]])
        end
      end

      context 'when response contains big data' do
        before { request_stub.to_return(body: big_string) }


        it 'handles streaming' do
          response = conn.public_send(http_method, '/') do |req|
            req.options.on_data = Proc.new { |*args| streamed << args }
          end

          expect(response.body).to eq('')
          check_streaming_response(streamed, chunk_size: 16 * 1024)
        end
      end
    end
  end

  on_feature :parallel do
    it 'handles parallel requests' do
      resp1, resp2 = nil, nil
      payload1 = { a: '1' }
      payload2 = { b: '2' }
      request_stub.with(Hash[query_or_body, payload1])
          .to_return(body: payload1.to_json)
      stub_request(http_method, remote).with(Hash[query_or_body, payload2])
          .to_return(body: payload2.to_json)

      conn.in_parallel do
        resp1 = conn.public_send(http_method, '/', payload1)
        resp2 = conn.public_send(http_method, '/', payload2)

        expect(conn.in_parallel?).to be_truthy
        expect(resp1.body).to be_nil
        expect(resp2.body).to be_nil
      end

      expect(conn.in_parallel?).to be_falsey
      expect(resp1.body).to eq(payload1.to_json)
      expect(resp2.body).to eq(payload2.to_json)
    end
  end

  # TODO: This needs reimplementation: see https://github.com/lostisland/faraday/issues/718
  # it 'handles open timeout responses' do
  #   request_stub.to_timeout
  #   expect { conn.public_send(http_method, '/') }.to raise_error(Faraday::Error::ConnectionFailed)
  # end

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
end