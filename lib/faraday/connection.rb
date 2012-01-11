require 'base64'
require 'cgi'
require 'set'
require 'forwardable'
require 'uri'

Faraday.require_libs 'builder', 'request', 'response', 'utils'

module Faraday
  class Connection
    METHODS = Set.new [:get, :post, :put, :delete, :head, :patch, :options]
    METHODS_WITH_BODIES = Set.new [:post, :put, :patch, :options]

    attr_accessor :parallel_manager
    attr_reader   :params, :headers, :url_prefix, :builder, :options, :ssl

    # :url
    # :params
    # :headers
    # :request
    # :ssl
    def initialize(url = nil, options = {})
      if url.is_a?(Hash)
        options = url
        url     = options[:url]
      end
      @headers          = Utils::Headers.new
      @params           = Utils::ParamsHash.new
      @options          = options[:request] || {}
      @ssl              = options[:ssl]     || {}
      @parallel_manager = options[:parallel]

      @builder = options[:builder] || begin
        # pass an empty block to Builder so it doesn't assume default middleware
        block = block_given?? Proc.new {|b| } : nil
        Builder.new(&block)
      end

      self.url_prefix = url || 'http:/'

      @params.update options[:params]   if options[:params]
      @headers.update options[:headers] if options[:headers]

      proxy(options.fetch(:proxy) { ENV['http_proxy'] })

      yield self if block_given?
    end

    # Public: Replace default query parameters.
    def params=(hash)
      @params.replace hash
    end

    # Public: Replace default request headers.
    def headers=(hash)
      @headers.replace hash
    end

    extend Forwardable
    def_delegators :builder, :build, :use, :request, :response, :adapter

    # The "rack app" wrapped in middleware. All requests are sent here.
    #
    # The builder is responsible for creating the app object. After this,
    # the builder gets locked to ensure no further modifications are made
    # to the middleware stack.
    #
    # Returns an object that responds to `call` and returns a Response.
    def app
      @app ||= begin
        builder.lock!
        builder.to_app(lambda { |env|
          # the inner app that creates and returns the Response object
          response = Response.new
          response.finish(env) unless env[:parallel_manager]
          env[:response] = response
        })
      end
    end

    # get/head/delete(url, params, headers)
    %w[get head delete].each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(url = nil, params = nil, headers = nil)
          run_request(:#{method}, url, nil, headers) { |request|
            request.params.update(params) if params
            yield request if block_given?
          }
        end
      RUBY
    end

    # post/put/patch(url, body, headers)
    %w[post put patch].each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(url = nil, body = nil, headers = nil, &block)
          run_request(:#{method}, url, body, headers, &block)
        end
      RUBY
    end

    def basic_auth(login, pass)
      @builder.insert(0, Faraday::Request::BasicAuthentication, login, pass)
    end

    def token_auth(token, options = {})
      @builder.insert(0, Faraday::Request::TokenAuthentication, token, options)
    end

    def in_parallel?
      !!@parallel_manager
    end

    def in_parallel(manager)
      @parallel_manager = manager
      yield
      @parallel_manager && @parallel_manager.run
    ensure
      @parallel_manager = nil
    end

    def proxy(arg = nil)
      return @proxy if arg.nil?

      @proxy = if arg.is_a? Hash
        uri = arg.fetch(:uri) { raise ArgumentError, "no :uri option" }
        arg.merge :uri => self.class.URI(uri)
      else
        {:uri => self.class.URI(arg)}
      end
    end

    # normalize URI() behavior across Ruby versions
    def self.URI url
      url.respond_to?(:host) ? url :
        url.respond_to?(:to_str) ? Kernel.URI(url) :
          raise(ArgumentError, "bad argument (expected URI object or URI string)")
    end

    def_delegators :url_prefix, :scheme, :scheme=, :host, :host=, :port, :port=
    def_delegator :url_prefix, :path, :path_prefix

    # Parses the giving url with URI and stores the individual
    # components in this connection.  These components serve as defaults for
    # requests made by this connection.
    #
    #   conn = Faraday::Connection.new { ... }
    #   conn.url_prefix = "https://sushi.com/api"
    #   conn.scheme      # => https
    #   conn.path_prefix # => "/api"
    #
    #   conn.get("nigiri?page=2") # accesses https://sushi.com/api/nigiri
    #
    def url_prefix=(url)
      uri = @url_prefix = self.class.URI(url)
      self.path_prefix = uri.path

      params.merge_query(uri.query)
      uri.query = nil

      if uri.user && uri.password
        basic_auth(CGI.unescape(uri.user), CGI.unescape(uri.password))
        uri.user = uri.password = nil
      end

      uri
    end

    # Ensures that the path prefix always has a leading but no trailing slash
    def path_prefix=(value)
      url_prefix.path = if value
        value = value.chomp '/'
        value = '/' + value unless value[0,1] == '/'
        value
      end
    end

    def run_request(method, url, body, headers)
      if !METHODS.include?(method)
        raise ArgumentError, "unknown http method: #{method}"
      end

      request = build_request(method) do |req|
        req.url(url)                if url
        req.headers.update(headers) if headers
        req.body = body             if body
        yield req if block_given?
      end

      env = request.to_env(self)
      self.app.call(env)
    end

    # Internal: Creates and configures the request object.
    #
    # Returns the new Request.
    def build_request(method)
      Request.create(method) do |req|
        req.params  = self.params.dup
        req.headers = self.headers.dup
        req.options = self.options.merge(:proxy => self.proxy)
        yield req if block_given?
      end
    end

    # Takes a relative url for a request and combines it with the defaults
    # set on the connection instance.
    #
    #   conn = Faraday::Connection.new { ... }
    #   conn.url_prefix = "https://sushi.com/api?token=abc"
    #   conn.scheme      # => https
    #   conn.path_prefix # => "/api"
    #
    #   conn.build_url("nigiri?page=2")      # => https://sushi.com/api/nigiri?token=abc&page=2
    #   conn.build_url("nigiri", :page => 2) # => https://sushi.com/api/nigiri?token=abc&page=2
    #
    def build_url(url, extra_params = nil)
      uri = build_exclusive_url(url)

      query_values = self.params.dup.merge_query(uri.query)
      query_values.update extra_params if extra_params
      uri.query = query_values.empty? ? nil : query_values.to_query

      uri
    end

    # Internal: Build an absolute URL based on url_prefix.
    #
    # url    - A String or URI-like object
    # params - A Faraday::Utils::ParamsHash to replace the query values
    #          of the resulting url (default: nil).
    #
    # Returns the resulting URI instance.
    def build_exclusive_url(url, params = nil)
      url = nil if url and url.empty?
      base = url_prefix
      if url and base.path and base.path !~ /\/$/
        base = base.dup
        base.path = base.path + '/'  # ensure trailing slash
      end
      uri = url ? base + url : base
      uri.query = params.to_query if params
      uri.query = nil if uri.query and uri.query.empty?
      uri
    end

    def dup
      self.class.new(build_url(''), :headers => headers.dup, :params => params.dup, :builder => builder.dup, :ssl => ssl.dup)
    end
  end
end
