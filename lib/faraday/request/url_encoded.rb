module Faraday
  # Middleware for supporting urlencoded requests.
  class Request::UrlEncoded < Faraday::Middleware
    CONTENT_TYPE = 'Content-Type'.freeze unless defined? CONTENT_TYPE

    class << self
      attr_accessor :mime_type
    end
    self.mime_type = 'application/x-www-form-urlencoded'.freeze

    # Encodes as "application/x-www-form-urlencoded" if not already encoded or
    # of another type.
    #
    # @param env [Faraday::Env]
    def call(env)
      match_content_type(env) do |data|
        params = Faraday::Utils::ParamsHash[data]
        env.body = params.to_query(env.params_encoder)
      end
      @app.call env
    end

    # @param env [Faraday::Env]
    # @yield [request_body] Body of the request
    def match_content_type(env)
      if process_request?(env)
        env.request_headers[CONTENT_TYPE] ||= self.class.mime_type
        yield(env.body) unless env.body.respond_to?(:to_str)
      end
    end

    # @param env [Faraday::Env]
    #
    # @return [Boolean] True if the request has a body and its Content-Type is
    #                   urlencoded.
    def process_request?(env)
      type = request_type(env)
      env.body and (type.empty? or type == self.class.mime_type)
    end

    # @param env [Faraday::Env]
    #
    # @return [String]
    def request_type(env)
      type = env.request_headers[CONTENT_TYPE].to_s
      type = type.split(';', 2).first if type.index(';')
      type
    end
  end
end
