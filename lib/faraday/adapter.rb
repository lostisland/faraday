# frozen_string_literal: true

module Faraday
  # Base class for all Faraday adapters. Adapters are
  # responsible for fulfilling a Faraday request.
  class Adapter
    extend MiddlewareRegistry
    extend DependencyLoader

    CONTENT_LENGTH = 'Content-Length'

    register_middleware File.expand_path('adapter', __dir__),
                        test: [:Test, 'test'],
                        net_http: [:NetHttp, 'net_http'],
                        net_http_persistent: [
                          :NetHttpPersistent,
                          'net_http_persistent'
                        ],
                        typhoeus: [:Typhoeus, 'typhoeus'],
                        patron: [:Patron, 'patron'],
                        em_synchrony: [:EMSynchrony, 'em_synchrony'],
                        em_http: [:EMHttp, 'em_http'],
                        excon: [:Excon, 'excon'],
                        rack: [:Rack, 'rack'],
                        httpclient: [:HTTPClient, 'httpclient']

    # This module marks an Adapter as supporting parallel requests.
    module Parallelism
      attr_writer :supports_parallel
      def supports_parallel?
        @supports_parallel
      end

      def inherited(subclass)
        super
        subclass.supports_parallel = supports_parallel?
      end
    end

    extend Parallelism
    self.supports_parallel = false

    def initialize(_app = nil, opts = {}, &block)
      @app = ->(env) { env.response }
      @connection_options = opts
      @config_block = block
    end

    def call(env)
      env.clear_body if env.needs_body?
      env.response = Response.new
    end

    private

    def save_response(env, status, body, headers = nil, reason_phrase = nil)
      env.status = status
      env.body = body
      env.reason_phrase = reason_phrase&.to_s&.strip
      env.response_headers = Utils::Headers.new.tap do |response_headers|
        response_headers.update headers unless headers.nil?
        yield(response_headers) if block_given?
      end

      env.response.finish(env) unless env.parallel?
      env.response
    end
  end
end
