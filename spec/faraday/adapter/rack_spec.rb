# frozen_string_literal: true

RSpec.describe Faraday::Adapter::Rack do
  features :request_body_on_query_methods, :trace_method, :connect_method, :skip_response_body_on_head

  it_behaves_like 'an adapter', adapter_options: (Class.new do
    def call(env)
      request_signature = WebMock::RequestSignature.new(req_method(env), req_uri(env),
                                                        body: req_body(env), headers: req_headers(env))
      WebMock::RequestRegistry.instance.requested_signatures.put(request_signature)

      process_response(request_signature)
    end

    def req_method(env)
      env['REQUEST_METHOD'].downcase.to_sym
    end

    def req_uri(env)
      url = +"#{env['rack.url_scheme']}://#{env['SERVER_NAME']}:#{env['SERVER_PORT']}#{env['PATH_INFO']}"
      url += "?#{env['QUERY_STRING']}" if env['QUERY_STRING']
      uri = WebMock::Util::URI.heuristic_parse(url)
      uri.path = uri.normalized_path.gsub('[^:]//', '/')
      uri
    end

    def req_headers(env)
      http_headers = env.select { |k, _| k.start_with?('HTTP_') }.map { |k, v| [k[5..-1], v] }.to_h
      http_headers.merge(env.slice('CONTENT_TYPE', 'CONTENT_LENGTH'))
    end

    def req_body(env)
      env['rack.input'].read
    end

    def process_response(request_signature)
      res = WebMock::StubRegistry.instance.response_for_request(request_signature)
      raise Faraday::ConnectionFailed, 'Trying to connect to localhost' if res.nil? && request_signature.uri.host == 'localhost'

      raise WebMock::NetConnectNotAllowedError, request_signature unless res

      raise Faraday::TimeoutError if res.should_timeout

      [res.status[0], res.headers || {}, [res.body || '']]
    end
  end).new
end
