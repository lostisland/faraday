# frozen_string_literal: true

RSpec.describe Faraday::Error do
  describe '.initialize' do
    subject { described_class.new(exception, response) }
    let(:response) { nil }

    context 'with exception only' do
      let(:exception) { RuntimeError.new('test') }

      it { expect(subject.wrapped_exception).to eq(exception) }
      it { expect(subject.response).to be_nil }
      it { expect(subject.message).to eq(exception.message) }
      it { expect(subject.backtrace).to eq(exception.backtrace) }
      it { expect(subject.inspect).to eq('#<Faraday::Error wrapped=#<RuntimeError: test>>') }
      it { expect(subject.response_status).to be_nil }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with response hash' do
      let(:exception) { { status: 400 } }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 400 - method and url are not available due to include_request: false on Faraday::Response::RaiseError middleware') }
      if RUBY_VERSION >= '3.4'
        it { expect(subject.inspect).to eq('#<Faraday::Error response={status: 400}>') }
      else
        it { expect(subject.inspect).to eq('#<Faraday::Error response={:status=>400}>') }
      end
      it { expect(subject.response_status).to eq(400) }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with string' do
      let(:exception) { 'custom message' }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to be_nil }
      it { expect(subject.message).to eq('custom message') }
      it { expect(subject.inspect).to eq('#<Faraday::Error #<Faraday::Error: custom message>>') }
      it { expect(subject.response_status).to be_nil }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with anything else #to_s' do
      let(:exception) { %w[error1 error2] }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to be_nil }
      it { expect(subject.message).to eq('["error1", "error2"]') }
      it { expect(subject.inspect).to eq('#<Faraday::Error #<Faraday::Error: ["error1", "error2"]>>') }
      it { expect(subject.response_status).to be_nil }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with exception string and response hash' do
      let(:exception) { 'custom message' }
      let(:response) { { status: 400 } }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(response) }
      it { expect(subject.message).to eq('custom message') }
      if RUBY_VERSION >= '3.4'
        it { expect(subject.inspect).to eq('#<Faraday::Error response={status: 400}>') }
      else
        it { expect(subject.inspect).to eq('#<Faraday::Error response={:status=>400}>') }
      end
      it { expect(subject.response_status).to eq(400) }
      it { expect(subject.response_headers).to be_nil }
      it { expect(subject.response_body).to be_nil }
    end

    context 'with exception and response object' do
      let(:exception) { RuntimeError.new('test') }
      let(:body) { { test: 'test' } }
      let(:headers) { { 'Content-Type' => 'application/json' } }
      let(:response) { Faraday::Response.new(status: 400, response_headers: headers, response_body: body) }

      it { expect(subject.wrapped_exception).to eq(exception) }
      it { expect(subject.response).to eq(response) }
      it { expect(subject.message).to eq(exception.message) }
      it { expect(subject.backtrace).to eq(exception.backtrace) }
      it { expect(subject.response_status).to eq(400) }
      it { expect(subject.response_headers).to eq(headers) }
      it { expect(subject.response_body).to eq(body) }
    end

    context 'with exception and a Faraday::Env marked include_request: false' do
      let(:exception) { RuntimeError.new('test') }
      let(:response) do
        env = Faraday::Env.from(
          status: 200,
          request_headers: { 'Authorization' => 'Bearer SECRET' },
          request_body: 'REQUEST-SECRET',
          response_headers: { 'Content-Type' => 'application/json' },
          response_body: 'ok'
        )
        env[:include_request] = false
        env[:custom_secret] = 'CUSTOM-SECRET'
        env
      end

      it 'replaces the response with a request-less Response' do
        sanitized_response = subject.response

        expect(sanitized_response).to be_a(Faraday::Response)
        expect(sanitized_response.env).not_to equal(response)
        expect(subject.response_status).to eq(200)
        expect(subject.response_headers).to eq('Content-Type' => 'application/json')
        expect(subject.response_body).to eq('ok')
        expect(sanitized_response.env.request_headers).to be_nil
        expect(sanitized_response.env.request_body).to be_nil
        expect(sanitized_response.env.url).to be_nil
        expect(sanitized_response.env[:custom_secret]).to be_nil
        expect(sanitized_response.env.response).to be_nil
        expect(subject.inspect).not_to include('SECRET')
      end
    end

    context 'with exception and a nil-status Faraday::Response marked include_request: false' do
      let(:exception) { RuntimeError.new('test') }
      let(:response) do
        env = Faraday::Env.from(
          status: nil,
          request_body: 'REQUEST-SECRET',
          response_body: 'RESPONSE-BODY'
        )
        env[:include_request] = false
        Faraday::Response.new(env)
      end

      it 'preserves the response body without retaining the request body' do
        expect(subject.response).to be_a(Faraday::Response)
        expect(subject.response.body).to eq('RESPONSE-BODY')
        expect(subject.response_body).to eq('RESPONSE-BODY')
        expect(subject.response.env.response_body).to eq('RESPONSE-BODY')
        expect(subject.response.env.request_body).to be_nil
        expect(subject.inspect).not_to include('REQUEST-SECRET')
      end
    end

    context 'with a Faraday::Env marked include_request: false as exception' do
      let(:exception) do
        env = Faraday::Env.from(
          method: :get,
          url: URI('https://example.com/secret?api_key=SECRET'),
          request_headers: { 'Authorization' => 'Bearer SECRET' },
          request_body: 'REQUEST-SECRET',
          status: 200,
          response_headers: { 'Content-Type' => 'application/json' },
          response_body: 'ok'
        )
        env[:include_request] = false
        env[:custom_secret] = 'CUSTOM-SECRET'
        env
      end

      it 'replaces the response with a request-less Response and message without the url' do
        sanitized_response = subject.response

        expect(sanitized_response).to be_a(Faraday::Response)
        expect(sanitized_response.env).not_to equal(exception)
        expect(subject.response_status).to eq(200)
        expect(subject.response_body).to eq('ok')
        expect(sanitized_response.env.method).to be_nil
        expect(sanitized_response.env.url).to be_nil
        expect(sanitized_response.env.request_headers).to be_nil
        expect(sanitized_response.env.request_body).to be_nil
        expect(sanitized_response.env[:custom_secret]).to be_nil
        expect(subject.message).to eq('the server responded with status 200 - method and url are not available due to include_request: false on Faraday::Response::RaiseError middleware')
        expect(subject.inspect).not_to include('SECRET')
      end
    end

    context 'with hash missing status key' do
      let(:exception) { { body: 'error body' } }

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status  - method and url are not available due to include_request: false on Faraday::Response::RaiseError middleware') }
    end

    context 'with hash with status but missing request data' do
      let(:exception) { { status: 404, body: 'not found' } } # missing request key

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 404 - method and url are not available due to include_request: false on Faraday::Response::RaiseError middleware') }
    end

    context 'with hash with status and request but missing method in request' do
      let(:exception) { { status: 404, body: 'not found', request: { url: 'http://example.com/test' } } } # missing method

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 404 for  http://example.com/test') }
    end

    context 'with hash with status and request but missing url in request' do
      let(:exception) { { status: 404, body: 'not found', request: { method: :get } } } # missing url

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 404 for GET ') }
    end

    context 'with properly formed Faraday::Env' do
      # This represents the normal case - a well-formed Faraday::Env object
      # with all the standard properties populated as they would be during
      # a typical HTTP request/response cycle
      let(:exception) { Faraday::Env.new }

      before do
        exception.status = 500
        exception.method = :post
        exception.url = URI('https://api.example.com/users')
        exception.request = Faraday::RequestOptions.new
        exception.response_headers = { 'content-type' => 'application/json' }
        exception.response_body = '{"error": "Internal server error"}'
        exception.request_headers = { 'authorization' => 'Bearer token123' }
        exception.request_body = '{"name": "John"}'
      end

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 500 for POST https://api.example.com/users') }
    end

    context 'with Faraday::Env missing status key' do
      let(:exception) { Faraday::Env.new }

      before do
        exception[:body] = 'error body'
        # Intentionally not setting status
      end

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status  for  ') }
    end

    context 'with Faraday::Env with direct method and url properties' do
      let(:exception) { Faraday::Env.new }

      before do
        exception.status = 404
        exception.method = :get
        exception.url = URI('http://example.com/test')
        exception[:body] = 'not found'
      end

      it { expect(subject.wrapped_exception).to be_nil }
      it { expect(subject.response).to eq(exception) }
      it { expect(subject.message).to eq('the server responded with status 404 for GET http://example.com/test') }
    end
  end
end
