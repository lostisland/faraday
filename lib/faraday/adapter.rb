module Faraday
  class Adapter < Middleware
    CONTENT_LENGTH = 'Content-Length'.freeze

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
      :Rack              => 'rack'

    register_middleware \
      :test                => :Test,
      :net_http            => :NetHttp,
      :net_http_persistent => :NetHttpPersistent,
      :typhoeus            => :Typhoeus,
      :patron              => :Patron,
      :em_synchrony        => :EMSynchrony,
      :em_http             => :EMHttp,
      :excon               => :Excon,
      :rack                => :Rack

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
