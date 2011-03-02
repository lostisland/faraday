module Faraday
  class Adapter < Middleware
    extend AutoloadHelper

    autoload_all 'faraday/adapter',
      :ActionDispatch => 'action_dispatch',
      :NetHttp        => 'net_http',
      :Typhoeus       => 'typhoeus',
      :EMSynchrony    => 'em_synchrony',
      :Patron         => 'patron',
      :Excon          => 'excon',
      :Test           => 'test',
      :Logger         => 'logger'

    register_lookup_modules \
      :action_dispatch => :ActionDispatch,
      :test            => :Test,
      :net_http        => :NetHttp,
      :typhoeus        => :Typhoeus,
      :patron          => :Patron,
      :em_synchrony    => :EMSynchrony,
      :excon           => :Excon,
      :logger          => :Logger

    def call(env)
      # do nothing
    end
  end
end
