module Faraday
  # Base class for all Faraday adapters. Adapters are
  # responsible for fulfilling a Faraday request.
  class Adapter
    extend MiddlewareRegistry
    extend DependencyLoader

    CONTENT_LENGTH = 'Content-Length'.freeze

    register_middleware File.expand_path('../adapter', __FILE__),
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

    # This module marks an Adapter as supporting parallel requests.
    module Parallelism
      attr_writer :supports_parallel

      def supports_parallel?()
        @supports_parallel
      end

      def inherited(subclass)
        subclass.supports_parallel = self.supports_parallel?
      end
    end

    extend Parallelism
    self.supports_parallel = false

    def initialize(opts = {}, &block)
      @app = lambda { |env| env.response }
      @connection_options = opts
      @config_block = block
    end

    def call(env)
      env.clear_body if env.needs_body?
      env.response ||= Response.new
    end

    private

    def save_response(env, status, body, headers = nil, reason_phrase = nil)
      params = { status: status, body: body, headers: headers, reason_phrase: reason_phrase&.to_s&.strip }
      env.parallel? ? env.response.apply_params(params) : env.response.finish(params)
      yield(env.response.headers) if block_given?
      env.response
    end
  end
end
