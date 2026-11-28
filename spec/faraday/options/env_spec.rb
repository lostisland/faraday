# frozen_string_literal: true

RSpec.describe Faraday::Env do
  subject(:env) { described_class.new }

  it 'allows to access members' do
    expect(env.method).to be_nil
    env.method = :get
    expect(env.method).to eq(:get)
  end

  it 'allows to access symbol non members' do
    expect(env[:custom]).to be_nil
    env[:custom] = :boom
    expect(env[:custom]).to eq(:boom)
  end

  it 'allows to access string non members' do
    expect(env['custom']).to be_nil
    env['custom'] = :boom
    expect(env['custom']).to eq(:boom)
  end

  it 'ignores false when fetching' do
    ssl = Faraday::SSLOptions.new
    ssl.verify = false
    expect(ssl.fetch(:verify, true)).to be_falsey
  end

  it 'handle verify_hostname when fetching' do
    ssl = Faraday::SSLOptions.new
    ssl.verify_hostname = true
    expect(ssl.fetch(:verify_hostname, false)).to be_truthy
  end

  it 'retains custom members' do
    env[:foo] = 'custom 1'
    env[:bar] = :custom2
    env2 = Faraday::Env.from(env)
    env2[:baz] = 'custom 3'

    expect(env2[:foo]).to eq('custom 1')
    expect(env2[:bar]).to eq(:custom2)
    expect(env[:baz]).to be_nil
  end

  it 'inherits from BaseOptions' do
    expect(described_class.superclass).to eq(Faraday::BaseOptions)
    expect(env).not_to be_a(Struct)
    expect(env).not_to be_a(Faraday::StructCompat)
    expect(described_class::MEMBERS).to eq(
      %i[method request_body url request request_headers ssl parallel_manager
         params response response_headers status reason_phrase response_body]
    )
  end

  it 'keeps the legacy constants' do
    expect(described_class::ContentLength).to eq('Content-Length')
    expect(described_class::StatusesWithoutBody).to eq(Set.new([204, 304]))
    expect(described_class::SuccessfulStatuses).to eq(200..299)
    expect(described_class::MethodsWithBodies).to include(:post, :put, :patch)
  end

  describe '#[] and #[]=' do
    it 'read and write members with symbols and strings' do
      env[:status] = 200
      env['reason_phrase'] = 'OK'

      expect(env.status).to eq(200)
      expect(env['status']).to eq(200)
      expect(env[:reason_phrase]).to eq('OK')
      expect(env.custom_members).to be_empty
    end

    it 'keep custom members under the key as given' do
      env[:custom] = 1
      env['custom'] = 2

      expect(env.custom_members).to eq(custom: 1, 'custom' => 2)
    end

    it 'do not coerce the value' do
      env[:request_headers] = { 'x' => '1' }
      env[:request] = { timeout: 1 }

      expect(env.request_headers).to be_an_instance_of(Hash)
      expect(env.request).to eq(timeout: 1)
    end
  end

  describe '.from and #update' do
    it 'coerce request, ssl and headers' do
      env = described_class.from(request: { timeout: 5 }, ssl: { verify: false },
                                 request_headers: { 'x-a' => '1' }, response_headers: { 'x-b' => '2' })

      expect(env.request.timeout).to eq(5)
      expect(env.ssl.verify).to be(false)
      expect(env.request_headers).to be_a(Faraday::Utils::Headers)
      expect(env.request_headers['X-A']).to eq('1')
      expect(env.response_headers['X-B']).to eq('2')
    end

    it 'skip false for the coerced members and keep the current value' do
      env.update(request: { timeout: 5 }, request_headers: { 'x-a' => '1' })
      env.update(request: false, request_headers: false, ssl: false)

      expect(env.request.timeout).to eq(5)
      expect(env.request_headers['X-A']).to eq('1')
      expect(env.ssl).to be_nil
    end

    it 'accept the body key, which follows the status set before it' do
      env.update(body: 'request')
      env.update(status: 200, body: 'response')

      expect(env.request_body).to eq('request')
      expect(env.response_body).to eq('response')
    end

    it 'raise on unknown keys' do
      expect { described_class.from(custom: 1) }.to raise_error(NoMethodError)
      expect { env.update(custom: 1) }.to raise_error(NoMethodError)
    end
  end

  describe '.from with an Env' do
    let(:original) do
      described_class.from(url: Faraday::Utils.URI('http://example.com'), request_body: 'body',
                           params: { a: 1 }, request: { timeout: 5 }, ssl: { verify: false },
                           request_headers: { 'X-A' => '1' })
    end

    it 'copies options, headers and Hash values and shares the rest' do
      copy = described_class.from(original)

      expect(copy.request.timeout).to eq(5)
      expect(copy.request).not_to equal(original.request)
      expect(copy.ssl).not_to equal(original.ssl)
      expect(copy.request_headers).to eq('X-A' => '1')
      expect(copy.request_headers).not_to equal(original.request_headers)
      expect(copy.params).to eq(a: 1)
      expect(copy.params).not_to equal(original.params)
      expect(copy.url).to equal(original.url)
      expect(copy.request_body).to equal(original.request_body)
    end
  end

  describe '#update' do
    it 'stores a copy of Hash values' do
      params = { a: 1 }
      env.update(params: params, request_body: { b: 2 })
      params[:c] = 3

      expect(env.params).to eq(a: 1)
      expect(env.request_body).to eq(b: 2)
    end
  end

  describe '#merge!' do
    it 'deep-merges the coerced members and replaces other Hash values' do
      env.update(request: { timeout: 5 }, request_headers: { 'X-A' => '1' }, params: { a: 1 },
                 request_body: { b: 1 })
      env.merge!(request: { open_timeout: 2 }, request_headers: { 'X-B' => '2' }, params: { c: 3 },
                 body: { d: 4 })

      expect(env.request.timeout).to eq(5)
      expect(env.request.open_timeout).to eq(2)
      expect(env.request_headers).to eq('X-A' => '1', 'X-B' => '2')
      expect(env.params).to eq(c: 3)
      expect(env.request_body).to eq(d: 4)
    end
  end

  describe '#dup' do
    it 'lets the copy unset members without changing the original' do
      env.update(status: 301, response_headers: { 'Location' => '/new' })
      copy = env.dup

      copy.delete(:status)
      copy.delete(:response_headers)

      expect(env.status).to eq(301)
      expect(env.response_headers).to eq('Location' => '/new')
    end
  end

  describe '#delete' do
    it 'unsets members, the body and custom members, and returns the value' do
      env.update(status: 200, response_body: 'body', request_body: 'request')
      env[:custom] = 1

      expect(env.delete(:status)).to eq(200)
      expect(env.delete(:body)).to eq('request')
      expect(env.delete(:custom)).to eq(1)
      expect(env.status).to be_nil
      expect(env.request_body).to be_nil
      expect(env.response_body).to eq('body')
      expect(env.custom_members).to be_empty
    end
  end

  describe '#dig' do
    it 'reads nested values' do
      env.response_headers = Faraday::Utils::Headers.new('Content-Type' => 'text/plain')

      expect(env.dig(:response_headers, 'Content-Type')).to eq('text/plain')
      expect(env.dig(:request_headers, 'Content-Type')).to be_nil
    end
  end

  describe '#to_hash' do
    it 'includes set members only, keeps options objects and skips custom members' do
      env.update(method: :get, request: { timeout: 5 })
      env[:custom] = 1

      expect(env.to_hash.keys).to eq(%i[method request])
      expect(env.to_hash[:request]).to equal(env.request)
    end
  end

  describe '#to_h' do
    it 'returns every member, nil included, like ruby_llm reads env.to_h' do
      env = described_class.from(request_body: 'prompt', request_headers: {})
      expect(env.to_h.values_at(:request_body, :request_headers, :status)).to eq(['prompt', {}, nil])
    end

    it 'leaves out custom members, like the legacy Struct' do
      env = described_class.new
      env[:custom] = 1
      expect(env.to_h).not_to have_key(:custom)
    end
  end

  describe '#deep_dup and #merge' do
    it 'copy the custom members' do
      env[:list] = [1]
      copy = env.deep_dup
      merged = env.merge(status: 200)

      expect(copy[:list]).to eq([1])
      expect(copy[:list]).not_to equal(env[:list])
      expect(merged[:list]).to eq([1])
      expect(merged.status).to eq(200)
      expect(env.status).to be_nil
    end

    it 'do not share the custom members with the original' do
      env[:list] = [1]
      copy = env.deep_dup
      copy[:other] = 2

      expect(env[:other]).to be_nil
    end
  end

  describe '.for_request' do
    it 'uses the objects of the request and the connection without copying them' do
      connection = Faraday.new(ssl: { verify: false })
      request = connection.build_request(:post) do |req|
        req.body = 'body'
        req.headers['X-A'] = '1'
        req.options.timeout = 5
      end
      url = Faraday::Utils.URI('http://example.com')

      env = described_class.for_request(request, url, connection)

      expect(env.method).to eq(:post)
      expect(env.request_body).to eq('body')
      expect(env.url).to equal(url)
      expect(env.request).to equal(request.options)
      expect(env.request_headers).to equal(request.headers)
      expect(env.ssl).to equal(connection.ssl)
      expect(env.parallel_manager).to be_nil
    end
  end

  describe 'helpers' do
    it 'report the status of the response' do
      expect(env.success?).to be(false)
      expect(env.parse_body?).to be(true)
      env.status = 204
      expect(env.success?).to be(true)
      expect(env.parse_body?).to be(false)
    end

    it 'know when a request needs a body and clear it' do
      env.update(method: :post, request_headers: {})
      expect(env.needs_body?).to be(true)

      env.clear_body

      expect(env.request_body).to eq('')
      expect(env.request_headers['Content-Length']).to be_nil
      expect(env.needs_body?).to be(false)
    end

    it 'report parallel mode' do
      expect(env.parallel?).to be(false)
      env.parallel_manager = Object.new
      expect(env.parallel?).to be(true)
    end

    it 'stream the response to the on_data callback' do
      chunks = []
      env.request = Faraday::RequestOptions.new(on_data: proc { |chunk, size| chunks << [chunk, size] })

      result = env.stream_response do |&on_chunk|
        on_chunk.call('ab')
        on_chunk.call('c')
        :done
      end

      expect(env.stream_response?).to be(true)
      expect(result).to eq(:done)
      expect(chunks).to eq([['ab', 2], ['c', 3]])
    end

    it 'call on_data once with an empty chunk when nothing is streamed' do
      chunks = []
      env.request = Faraday::RequestOptions.new(on_data: proc { |chunk, size| chunks << [chunk, size] })

      env.stream_response { nil }

      expect(chunks).to eq([['', 0]])
    end

    it 'delegate params_encoder to the request options' do
      env.request = Faraday::RequestOptions.new(params_encoder: Faraday::FlatParamsEncoder)
      expect(env.params_encoder).to eq(Faraday::FlatParamsEncoder)
    end
  end

  describe '#inspect' do
    it 'shows the set members and the custom members' do
      env.update(method: :get, status: 200)
      env[:custom] = 1

      expect(env.inspect).to eq("#<Faraday::Env @method=:get @status=200 @custom=#{{ custom: 1 }.inspect}>")
    end
  end

  describe '#body' do
    subject(:env) { described_class.from(body: { foo: 'bar' }) }

    context 'when response is not finished yet' do
      it 'returns the request body' do
        expect(env.body).to eq(foo: 'bar')
      end
    end

    context 'when response is finished' do
      before do
        env.status = 200
        env.body = { bar: 'foo' }
        env.response = Faraday::Response.new(env)
      end

      it 'returns the response body' do
        expect(env.body).to eq(bar: 'foo')
      end

      it 'allows to access request_body' do
        expect(env.request_body).to eq(foo: 'bar')
      end

      it 'allows to access response_body' do
        expect(env.response_body).to eq(bar: 'foo')
      end
    end
  end
end
