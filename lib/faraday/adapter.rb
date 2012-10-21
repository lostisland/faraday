module Faraday
  # Public: This is a base class for all Faraday adapters.  Adapters are
  # responsible for fulfilling a Faraday request.
  class Adapter < Middleware
    extend AutoloadHelper
    extend MiddlewareRegistry

    autoload_all 'faraday/adapter',
      :NetHttp           => 'net_http',
      :NetHttpPersistent => 'net_http_persistent',
      :Typhoeus          => 'typhoeus',
      :EMSynchrony       => 'em_synchrony',
      :EMHttp            => 'em_http',
      :Patron            => 'patron',
      :Excon             => 'excon',
      :Test              => 'test',
      :Rack              => 'rack',
      :HTTPClient        => 'httpclient'

    register_middleware \
      :test                => :Test,
      :net_http            => :NetHttp,
      :net_http_persistent => :NetHttpPersistent,
      :typhoeus            => :Typhoeus,
      :patron              => :Patron,
      :em_synchrony        => :EMSynchrony,
      :em_http             => :EMHttp,
      :excon               => :Excon,
      :rack                => :Rack,
      :httpclient          => :HTTPClient

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
      env.clear_body if env.needs_body?
    end

    def save_response(env, status, body, headers = nil)
      env.status = status
      env.body = body
      env.response_headers = Utils::Headers.new.tap do |response_headers|
        response_headers.update headers unless headers.nil?
        yield response_headers if block_given?
      end
    end
  end
end
