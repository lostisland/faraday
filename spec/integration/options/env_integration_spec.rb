# frozen_string_literal: true

RSpec.describe Faraday::Env, type: :integration do
  # Middleware that hands the env to a block when the request goes out and when
  # the response comes back.
  def env_middleware(on_request: nil, on_complete: nil)
    Class.new(Faraday::Middleware) do
      define_method(:on_request) { |env| on_request&.call(env) }
      define_method(:on_complete) { |env| on_complete&.call(env) }
    end
  end

  def connection_with(middleware, **options)
    httpbin_connection(options) { |f| f.use middleware }
  end

  def json(response)
    JSON.parse(response.body)
  end

  describe 'request lifecycle' do
    it 'describes the request on its way out' do
      seen = nil
      conn = connection_with(env_middleware(on_request: ->(env) { seen = env.dup }),
                             headers: { 'X-Test' => 'a' }, request: { timeout: 5 })

      conn.post('/post?from_url=1', 'payload', 'Content-Type' => 'text/plain')

      expect(seen.method).to eq(:post)
      expect(seen.url.to_s).to eq("#{Faraday::IntegrationHelpers::HTTPBIN_URL}/post?from_url=1")
      expect(seen.request_body).to eq('payload')
      expect(seen.request_headers).to include('X-Test' => 'a', 'Content-Type' => 'text/plain')
      expect(seen.request).to be_a(Faraday::RequestOptions)
      expect(seen.request.timeout).to eq(5)
      expect(seen.ssl).to be_a(Faraday::SSLOptions)
    end

    it 'has no response members before the request is made' do
      seen = nil
      conn = connection_with(env_middleware(on_request: lambda { |env|
        seen = [env.status, env.response_body, env.response_headers, env.reason_phrase, env.response, env.success?]
      }))

      conn.get('/get')

      expect(seen).to eq([nil, nil, nil, nil, nil, false])
    end

    it 'describes the response on its way back' do
      seen = nil
      conn = connection_with(env_middleware(on_complete: ->(env) { seen = env.dup }))

      conn.get('/status/201')

      expect(seen.status).to eq(201)
      expect(seen.success?).to be(true)
      expect(seen.reason_phrase).to eq('CREATED')
      expect(seen.response_headers).to be_a(Faraday::Utils::Headers)
      expect(seen.response_headers['content-type']).to include('text/html')
      expect(seen.response).to be_a(Faraday::Response)
    end

    it 'is the same env that the response exposes' do
      conn = httpbin_connection
      response = conn.get('/get')

      expect(response.env).to be_a(described_class)
      expect(response.env.status).to eq(response.status)
      expect(response.env.method).to eq(:get)
      expect(response.env.url.path).to eq('/get')
      expect(response.env.response_body).to eq(response.body)
    end

    it 'reports unsuccessful statuses' do
      response = httpbin_connection.get('/status/404')

      expect(response.env.success?).to be(false)
      expect(response.env.status).to eq(404)
    end

    it 'detects statuses that have no body' do
      no_content_env = httpbin_connection.get('/status/204').env
      ok_env = httpbin_connection.get('/get').env

      expect(no_content_env.parse_body?).to be(false)
      expect(ok_env.parse_body?).to be(true)
    end
  end

  describe 'body handling' do
    it 'reads the request body before a response and the response body after' do
      before_response = nil
      after_response = nil
      conn = connection_with(env_middleware(
                               on_request: ->(env) { before_response = [env.body, env[:body]] },
                               on_complete: ->(env) { after_response = [env.body, env[:body]] }
                             ))

      conn.post('/post', 'sent')

      expect(before_response).to eq(%w[sent sent])
      expect(after_response.first).to include('"data": "sent"')
      expect(after_response.last).to eq(after_response.first)
    end

    it 'lets middleware replace the request body' do
      rewrite = env_middleware(on_request: ->(env) { env.body = env.body.reverse })
      conn = connection_with(rewrite)

      response = conn.post('/post', 'abc')

      expect(json(response)['data']).to eq('cba')
      expect(response.env.request_body).to eq('cba')
    end

    it 'lets middleware replace the response body' do
      conn = connection_with(env_middleware(on_complete: ->(env) { env.body = { wrapped: env.body.bytesize.positive? } }))

      response = conn.get('/get')

      expect(response.body).to eq(wrapped: true)
      expect(response.env.response_body).to eq(wrapped: true)
    end

    it 'distinguishes the request body from the response body' do
      response = httpbin_connection.post('/post', 'sent', 'Content-Type' => 'text/plain')

      expect(response.env.request_body).to eq('sent')
      expect(response.env.response_body).to include('"data": "sent"')
      expect(response.env.body).to eq(response.env.response_body)
    end

    it 'knows which requests need a body' do
      needs = []
      conn = connection_with(env_middleware(on_request: ->(env) { needs << [env.method, env.needs_body?] }))

      conn.get('/get')
      conn.post('/post')
      conn.post('/post', 'x')

      expect(needs).to eq([[:get, false], [:post, true], [:post, false]])
    end

    it 'can clear the body of a request' do
      clear = env_middleware(on_request: ->(env) { env.clear_body if env.needs_body? })
      conn = connection_with(clear)

      response = conn.post('/post')

      expect(response.env.request_headers['Content-Length']).to eq('0')
      expect(json(response)['data']).to eq('')
    end
  end

  describe 'member access' do
    it 'reads members through accessors, [] with symbols and [] with strings' do
      env = httpbin_connection.get('/get').env

      expect(env.status).to eq(200)
      expect(env[:status]).to eq(200)
      expect(env['status']).to eq(200)
    end

    it 'writes members through accessors and []=' do
      seen = nil
      conn = connection_with(env_middleware(on_request: lambda { |env|
        env[:request_headers]['X-One'] = '1'
        env.request_headers['X-Two'] = '2'
        env[:url] = env.url.dup.tap { |url| url.path = '/anything/rewritten' }
        seen = env.method
      }))

      response = conn.get('/get')

      expect(seen).to eq(:get)
      expect(json(response)['headers']).to include('X-One' => '1', 'X-Two' => '2')
      expect(json(response)['url']).to end_with('/anything/rewritten')
    end

    it 'lets middleware change the HTTP method' do
      conn = connection_with(env_middleware(on_request: ->(env) { env.method = :delete }))

      response = conn.get('/delete')

      expect(response.status).to eq(200)
      expect(response.env.method).to eq(:delete)
    end

    it 'coerces request_headers and response_headers to Faraday::Utils::Headers' do
      env = httpbin_connection(headers: { 'x-test' => 'a' }).get('/get').env

      expect(env.request_headers).to be_a(Faraday::Utils::Headers)
      expect(env.request_headers['X-TEST']).to eq('a')
      expect(env.response_headers).to be_a(Faraday::Utils::Headers)
      expect(env.response_headers['CONTENT-TYPE']).to eq('application/json')
    end

    it 'delegates params_encoder to the request options' do
      env = httpbin_connection(request: { params_encoder: Faraday::FlatParamsEncoder }).get('/get').env

      expect(env.params_encoder).to eq(Faraday::FlatParamsEncoder)
      expect(env.params_encoder).to eq(env.request.params_encoder)
    end

    it 'exposes the request options to middleware' do
      seen = nil
      conn = connection_with(env_middleware(on_request: ->(env) { seen = env.request.to_hash }),
                             request: { timeout: 3, open_timeout: 2 })

      conn.get('/get') { |req| req.options.read_timeout = 4 }

      expect(seen).to include(timeout: 3, open_timeout: 2, read_timeout: 4)
    end

    it 'exposes a streaming callback through the request options' do
      streamed = []
      stream_flags = []
      conn = connection_with(env_middleware(on_request: ->(env) { stream_flags << env.stream_response? }))

      conn.get('/stream-bytes/100') { |req| req.options.on_data = proc { |chunk, _| streamed << chunk } }
      conn.get('/stream-bytes/100')

      expect(streamed.join.bytesize).to eq(100)
      expect(stream_flags).to eq([true, false])
    end

    it 'reports whether the request runs in parallel mode' do
      env = httpbin_connection.get('/get').env

      expect(env.parallel?).to be(false)
      expect(env.parallel_manager).to be_nil
    end
  end

  describe 'custom members' do
    it 'stores arbitrary keys set by middleware' do
      seen = nil
      set = env_middleware(on_request: lambda { |env|
        env[:trace_id] = 'abc-123'
        env['string_key'] = 'string'
      })
      read = env_middleware(on_request: ->(env) { seen = [env[:trace_id], env['string_key'], env[:missing]] })
      conn = httpbin_connection do |f|
        f.use set
        f.use read
      end

      conn.get('/get')

      expect(seen).to eq(['abc-123', 'string', nil])
    end

    it 'keeps custom members on the env returned with the response' do
      conn = connection_with(env_middleware(on_request: ->(env) { env[:trace_id] = 'abc-123' }))

      response = conn.get('/get')

      expect(response.env[:trace_id]).to eq('abc-123')
      expect(response.env.custom_members).to eq(trace_id: 'abc-123')
    end

    it 'shows custom members when inspecting the env' do
      conn = connection_with(env_middleware(on_request: ->(env) { env[:trace_id] = 'abc-123' }))

      expect(conn.get('/get').env.inspect).to match(/@custom=.*trace_id.*abc-123/)
    end

    it 'does not share custom members between requests' do
      seen = []
      conn = connection_with(env_middleware(on_request: lambda { |env|
        seen << env[:counter]
        env[:counter] = :set
      }))

      2.times { conn.get('/get') }

      expect(seen).to eq([nil, nil])
    end

    it 'preserves custom members when building an env from another one' do
      env = httpbin_connection.get('/get').env
      env[:note] = 'kept'

      copy = described_class.from(env)

      expect(copy[:note]).to eq('kept')
      expect(copy.status).to eq(200)
      expect(copy).not_to equal(env)
    end
  end

  describe 'on_complete callbacks' do
    it 'passes the env to on_complete blocks of the response' do
      response = httpbin_connection.get('/get')
      envs = []

      response.on_complete { |env| envs << env }

      expect(envs).to eq([response.env])
    end
  end
end
