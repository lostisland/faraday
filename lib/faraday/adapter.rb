module Faraday
  class Adapter < Middleware
    CONTENT_LENGTH = 'Content-Length'.freeze

    extend AutoloadHelper

    autoload_all 'faraday/adapter',
      :ActionDispatch => 'action_dispatch',
      :NetHttp        => 'net_http',
      :Typhoeus       => 'typhoeus',
      :EMSynchrony    => 'em_synchrony',
      :Patron         => 'patron',
      :Excon          => 'excon',
      :Test           => 'test'

    register_lookup_modules \
      :action_dispatch => :ActionDispatch,
      :test            => :Test,
      :net_http        => :NetHttp,
      :typhoeus        => :Typhoeus,
      :patron          => :Patron,
      :em_synchrony    => :EMSynchrony,
      :excon           => :Excon

    def call(env)
      if !env[:body] and Connection::METHODS_WITH_BODIES.include? env[:method]
        # play nice and indicate we're sending an empty body
        env[:request_headers][CONTENT_LENGTH] = "0"
        # Typhoeus hangs on PUT requests if body is nil
        env[:body] = ''
      end
    end

    def response_headers(env)
      env[:response_headers] ||= Utils::Headers.new
    end
  end
end
