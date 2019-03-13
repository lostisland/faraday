# frozen_string_literal: true

require 'faraday/adapter_registry'

module Faraday
  # A Builder that processes requests into responses by passing through an inner
  # middleware stack (heavily inspired by Rack).
  #
  #   Faraday::Connection.new(url: 'http://sushi.com') do |builder|
  #     builder.request  :url_encoded  # Faraday::Request::UrlEncoded
  #     builder.adapter  :net_http     # Faraday::Adapter::NetHttp
  #   end
  class RackBuilder
    attr_accessor :handlers

    def initialize(handlers = [], adapter = nil, &block)
      @adapter = adapter
      @handlers = handlers
      if block_given?
        build(&block)
      elsif @handlers.empty?
        # default stack, if nothing else is configured
        request :url_encoded
        self.adapter Faraday.default_adapter
      end
    end

    def [](idx)
      @handlers[idx]
    end

    # Locks the middleware stack to ensure no further modifications are made.
    def lock!
      @handlers.freeze
    end

    def locked?
      @handlers.frozen?
    end

    # Processes a Request into a Response by passing it through this Builder's
    # middleware stack.
    #
    # connection - Faraday::Connection
    # request    - Faraday::Request
    #
    # Returns a Faraday::Response.
    def build_response(connection, request)
      app.call(build_env(connection, request))
    end

    # The "rack app" wrapped in middleware. All requests are sent here.
    #
    # The builder is responsible for creating the app object. After this,
    # the builder gets locked to ensure no further modifications are made
    # to the middleware stack.
    #
    # Returns an object that responds to `call` and returns a Response.
    def app
      @app ||= begin
        lock!
        to_app
      end
    end

    def to_app
      # last added handler is the deepest and thus closest to the inner app
      # adapter is always the last one
      @handlers.reverse.inject(@adapter.build) do |app, handler|
        handler.build(app)
      end
    end

    def ==(other)
      other.is_a?(self.class) &&
        @handlers == other.handlers &&
        @adapter == other.adapter
    end

    def dup
      self.class.new(@handlers.dup, @adapter.dup)
    end

    # ENV Keys
    # :method - a symbolized request method (:get, :post)
    # :body   - the request body that will eventually be converted to a string.
    # :url    - URI instance for the current request.
    # :status           - HTTP response status code
    # :request_headers  - hash of HTTP Headers to be sent to the server
    # :response_headers - Hash of HTTP headers from the server
    # :parallel_manager - sent if the connection is in parallel mode
    # :request - Hash of options for configuring the request.
    #   :timeout      - open/read timeout Integer in seconds
    #   :open_timeout - read timeout Integer in seconds
    #   :proxy        - Hash of proxy options
    #     :uri        - Proxy Server URI
    #     :user       - Proxy server username
    #     :password   - Proxy server password
    # :ssl - Hash of options for configuring SSL requests.
    def build_env(connection, request)
      exclusive_url = connection.build_exclusive_url(
        request.path, request.params,
        request.options.params_encoder
      )

      Env.new(request.method, request.body, exclusive_url,
              request.options, request.headers, connection.ssl,
              connection.parallel_manager)
    end
  end
end

require 'faraday/rack_builder/handler'
require 'faraday/rack_builder/stack_management'

Faraday::RackBuilder.include Faraday::StackManagement
