# frozen_string_literal: true

RSpec.describe Faraday::RequestOptions do
  describe 'timeout option' do
    it 'raises TimeoutError when request exceeds timeout' do
      conn = httpbin_connection(request: { timeout: 1 })

      expect do
        conn.get('/delay/3') # Delay 3 seconds, but timeout is 1 second
      end.to raise_error(Faraday::TimeoutError)
    end

    it 'completes successfully when request is within timeout' do
      conn = httpbin_connection(request: { timeout: 3 })

      response = conn.get('/delay/1') # Delay 1 second, timeout is 3 seconds
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['url']).to include('/delay/1')
    end
  end

  describe 'streaming with on_data' do
    it 'streams response body in chunks' do
      conn = httpbin_connection
      chunks = []

      # Use httpbin's chunk_size parameter to control server chunking
      # Request 1000 bytes in 100-byte chunks = 10 chunks
      byte_count = 1000
      chunk_size = 100

      conn.get("/stream-bytes/#{byte_count}?chunk_size=#{chunk_size}") do |req|
        req.options.on_data = proc do |chunk, _size_total|
          # NOTE: size param is cumulative total, not current chunk size
          chunks << chunk
        end
      end

      # Validate streaming callback received all data
      expect(chunks).not_to be_empty
      expect(chunks.join.bytesize).to eq(byte_count)

      # Validate data arrived in expected chunks
      # httpbin's chunk_size parameter ensures predictable chunking
      expect(chunks.length).to eq(10)
      expect(chunks.map(&:bytesize)).to all(eq(chunk_size))
    end

    it 'returns empty body when streaming' do
      conn = httpbin_connection
      response = conn.get('/stream-bytes/500') do |req|
        req.options.on_data = proc do |chunk, _size|
          # Just consume the chunks
        end
      end

      # When streaming, response body should be empty
      expect(response.body).to eq('')
    end

    it 'does not stream without on_data callback' do
      conn = httpbin_connection
      response = conn.get('/stream-bytes/500')

      expect(response.body).not_to be_empty
      expect(response.body.bytesize).to eq(500)
    end
  end

  describe 'params encoding' do
    let(:conn) { httpbin_connection }

    it 'sends query parameters with default encoder' do
      response = conn.get('/get', name: 'Ruby', version: '3.3')

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['args']).to eq('name' => 'Ruby', 'version' => '3.3')
    end

    it 'sends nested parameters' do
      response = conn.get('/get', user: { name: 'Alice', id: 123 })

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      # Default encoder flattens nested params
      expect(json['args']).to include('user[name]' => 'Alice', 'user[id]' => '123')
    end

    it 'handles array parameters' do
      response = conn.get('/get', tags: %w[ruby http client])

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      # Default encoder handles arrays
      expect(json['args']).to have_key('tags[]')
    end

    it 'encodes special characters' do
      response = conn.get('/get', message: 'Hello, World!')

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['args']['message']).to eq('Hello, World!')
    end

    it 'uses custom params encoder' do
      # Custom encoder that joins array values with commas
      custom_encoder = Faraday::FlatParamsEncoder

      conn_with_encoder = httpbin_connection(request: { params_encoder: custom_encoder })
      response = conn_with_encoder.get('/get', tags: %w[ruby http])

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['url']).to include('tags')
    end
  end

  describe 'request headers' do
    let(:conn) { httpbin_connection }

    it 'sends custom headers' do
      response = conn.get('/get') do |req|
        req.headers['X-Custom-Header'] = 'CustomValue'
        req.headers['User-Agent'] = 'Faraday Integration Test'
      end

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['headers']['X-Custom-Header']).to eq('CustomValue')
      expect(json['headers']['User-Agent']).to eq('Faraday Integration Test')
    end
  end

  describe 'request body' do
    let(:conn) { httpbin_connection }

    it 'sends POST request with body' do
      response = conn.post('/post') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = JSON.generate(message: 'Hello from Faraday')
      end

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['data']).to eq('{"message":"Hello from Faraday"}')
      expect(json['headers']['Content-Type']).to eq('application/json')
    end

    it 'sends form-encoded POST request' do
      response = conn.post('/post', name: 'Alice', age: 30)

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['form']).to eq('name' => 'Alice', 'age' => '30')
    end
  end

  describe 'HTTP methods' do
    let(:conn) { httpbin_connection }

    it 'performs GET request' do
      response = conn.get('/get')
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json).to have_key('url')
    end

    it 'performs POST request' do
      response = conn.post('/post', data: 'test')
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json).to have_key('form')
    end

    it 'performs PUT request' do
      response = conn.put('/put', data: 'test')
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json).to have_key('form')
    end

    it 'performs PATCH request' do
      response = conn.patch('/patch', data: 'test')
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json).to have_key('form')
    end

    it 'performs DELETE request' do
      response = conn.delete('/delete')
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json).to have_key('url')
    end

    it 'performs HEAD request' do
      response = conn.head('/get')
      expect(response.status).to eq(200)
      expect(response.body).to be_empty
    end
  end

  describe 'response handling' do
    let(:conn) { httpbin_connection }

    it 'handles different status codes' do
      [200, 201, 400, 404, 500].each do |code|
        response = conn.get("/status/#{code}")
        expect(response.status).to eq(code)
      end
    end

    it 'receives redirect responses' do
      # Faraday does NOT follow redirects by default (requires middleware)
      response = conn.get('/redirect/1')
      expect(response.status).to eq(302)
      expect(response.headers['location']).not_to be_nil
    end

    it 'parses JSON response body' do
      response = conn.get('/json')
      expect(response.status).to eq(200)

      json = JSON.parse(response.body)
      expect(json).to be_a(Hash)
    end
  end
end
