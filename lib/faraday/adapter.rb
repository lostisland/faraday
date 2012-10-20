module Faraday
  # Public: This is a base class for all Faraday adapters.  Adapters are
  # responsible for fulfilling a Faraday request.
  class Adapter < Middleware
    CONTENT_LENGTH = 'Content-Length'.freeze

    extend MiddlewareRegistry

    register_middleware 'faraday/adapter',
      :test => [:Test, 'test'],
      :net_http => [:NetHttp, 'net_http'],
      :net_http_persistent => [:NetHttpPersistent, 'net_http_persistent'],
      :typhoeus => [:Typhoeus, 'typhoeus'],
      :patron => [:Patron, 'patron'],
      :em_synchrony => [:EMSynchrony, 'em_synchrony'],
      :em_http => [:EMHttp, 'em_http'],
      :excon => [:Excon, 'excon'],
      :rack => [:Rack, 'rack'],
      :httpclient => [:HTTPClient, 'httpclient']

    # Public: This module marks an Adapter as supporting parallel requests.
    module Parallelism
      attr_writer :supports_parallel
      def supports_parallel?() @supports_parallel end

      def inherited(subclass)
        super
        subclass.supports_parallel = self.supports_parallel?
      end
    end

    extend Parallelism
    self.supports_parallel = false

    def call(env)
      if !env[:body] and Connection::METHODS_WITH_BODIES.include? env[:method]
        # play nice and indicate we're sending an empty body
        env[:request_headers][CONTENT_LENGTH] = "0"
        # Typhoeus hangs on PUT requests if body is nil
        env[:body] = ''
      end
    end

    def save_response(env, status, body, headers = nil)
      env[:status] = status
      env[:body] = body
      env[:response_headers] = Utils::Headers.new.tap do |response_headers|
        response_headers.update headers unless headers.nil?
        yield response_headers if block_given?
      end
    end
  end
end
