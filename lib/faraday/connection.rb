# frozen_string_literal: true

module Faraday
  # Connection objects manage the default properties and the middleware
  # stack for fulfilling an HTTP request.
  #
  # @example
  #
  #   conn = Faraday::Connection.new 'http://sushi.com'
  #
  #   # GET http://sushi.com/nigiri
  #   conn.get 'nigiri'
  #   # => #<Faraday::Response>
  #
  class Connection
    extend Forwardable

    # A Set of allowed HTTP verbs.
    METHODS = Set.new %i[get post put delete head patch options trace connect]

    # @return [Hash] URI query unencoded key/value pairs.
    attr_reader :params

    # @return [Hash] unencoded HTTP header key/value pairs.
    attr_reader :headers

    # @return [String] a URI with the prefix used for all requests from this
    #   Connection. This includes a default host name, scheme, port, and path.
    attr_reader :url_prefix

    # @return [Faraday::Builder] Builder for this Connection.
    attr_reader :builder

    # @return [Hash] SSL options.
    attr_reader :ssl

    # @return [Object] the parallel manager for this Connection.
    attr_reader :parallel_manager

    # Sets the default parallel manager for this connection.
    attr_writer :default_parallel_manager

    # @return [Hash] proxy options.
    attr_reader :proxy

    # Initializes a new Faraday::Connection.
    #
    # @param url [URI, String] URI or String base URL to use as a prefix for all
    #           requests (optional).
    # @param options [Hash, Faraday::ConnectionOptions]
    # @option options [URI, String] :url ('http:/') URI or String base URL
    # @option options [Hash<String => String>] :params URI query unencoded
    #                 key/value pairs.
    # @option options [Hash<String => String>] :headers Hash of unencoded HTTP
    #                 header key/value pairs.
    # @option options [Hash] :request Hash of request options.
    # @option options [Hash] :ssl Hash of SSL options.
    # @option options [Hash, URI, String] :proxy proxy options, either as a URL
    #                 or as a Hash
    # @option options [URI, String] :proxy[:uri]
    # @option options [String] :proxy[:user]
    # @option options [String] :proxy[:password]
    # @yield [self] after all setup has been done
    def initialize(url = nil, options = nil)
      options = ConnectionOptions.from(options)

      if url.is_a?(Hash) || url.is_a?(ConnectionOptions)
        options = options.merge(url)
        url     = options.url
      end

      @parallel_manager = nil
      @headers = Utils::Headers.new
      @params  = Utils::ParamsHash.new
      @options = options.request
      @ssl = options.ssl
      @default_parallel_manager = options.parallel_manager

      @builder = options.builder || begin
        # pass an empty block to Builder so it doesn't assume default middleware
        options.new_builder(block_given? ? proc { |b| } : nil)
      end

      self.url_prefix = url || 'http:/'

      @params.update(options.params)   if options.params
      @headers.update(options.headers) if options.headers

      initialize_proxy(url, options)

      yield(self) if block_given?

      @headers[:user_agent] ||= "Faraday v#{VERSION}"
    end

    # Sets the Hash of URI query unencoded key/value pairs.
    # @param hash [Hash]
    def params=(hash)
      @params.replace hash
    end

    # Sets the Hash of unencoded HTTP header key/value pairs.
    # @param hash [Hash]
    def headers=(hash)
      @headers.replace hash
    end

    # Sets the Hash proxy options.
    #
    # @param new_value [Object]
    def proxy=(new_value)
      @manual_proxy = true
      @proxy = new_value ? ProxyOptions.from(new_value) : nil
    end

    def_delegators :url_prefix, :scheme, :scheme=, :host, :host=, :port, :port=
    def_delegator :url_prefix, :path, :path_prefix

    # Parses the given URL with URI and stores the individual
    # components in this connection. These components serve as defaults for
    # requests made by this connection.
    #
    # @param url [String, URI]
    # @param encoder [Object]
    #
    # @example
    #
    #   conn = Faraday::Connection.new { ... }
    #   conn.url_prefix = "https://sushi.com/api"
    #   conn.scheme      # => https
    #   conn.path_prefix # => "/api"
    #
    #   conn.get("nigiri?page=2") # accesses https://sushi.com/api/nigiri
    def url_prefix=(url, encoder = nil)
      uri = @url_prefix = Utils.URI(url)
      self.path_prefix = uri.path

      params.merge_query(uri.query, encoder)
      uri.query = nil

      with_uri_credentials(uri) do |user, password|
        basic_auth user, password
        uri.user = uri.password = nil
      end
    end

    # Sets the path prefix and ensures that it always has a leading
    # slash.
    #
    # @param value [String]
    #
    # @return [String] the new path prefix
    def path_prefix=(value)
      url_prefix.path = if value
                          value = '/' + value unless value[0, 1] == '/'
                          value
                        end
    end

    def_delegators :builder, :build, :use, :request, :response, :adapter, :app

    # @!method get(url = nil, params = nil, headers = nil)
    # Makes a GET HTTP request without a body.
    # @!scope class
    #
    # @param url [String] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param params [Hash] Hash of URI query unencoded key/value pairs.
    # @param headers [Hash] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.get '/items', { page: 1 }, :accept => 'application/json'
    #
    #   # ElasticSearch example sending a body with GET.
    #   conn.get '/twitter/tweet/_search' do |req|
    #     req.headers[:content_type] = 'application/json'
    #     req.params[:routing] = 'kimchy'
    #     req.body = JSON.generate(query: {...})
    #   end
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]

    # @!method head(url = nil, params = nil, headers = nil)
    # Makes a HEAD HTTP request without a body.
    # @!scope class
    #
    # @param url [String] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param params [Hash] Hash of URI query unencoded key/value pairs.
    # @param headers [Hash] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.head '/items/1'
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]

    # @!method delete(url = nil, params = nil, headers = nil)
    # Makes a DELETE HTTP request without a body.
    # @!scope class
    #
    # @param url [String] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param params [Hash] Hash of URI query unencoded key/value pairs.
    # @param headers [Hash] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.delete '/items/1'
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]

    # @!method connect(url = nil, params = nil, headers = nil)
    # Makes a CONNECT HTTP request without a body.
    # @!scope class
    #
    # @param url [String] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param params [Hash] Hash of URI query unencoded key/value pairs.
    # @param headers [Hash] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.connect '/items/1'
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]

    # @!method trace(url = nil, params = nil, headers = nil)
    # Makes a TRACE HTTP request without a body.
    # @!scope class
    #
    # @param url [String] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param params [Hash] Hash of URI query unencoded key/value pairs.
    # @param headers [Hash] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.connect '/items/1'
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]

    # @!visibility private
    METHODS_WITH_QUERY.each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(url = nil, params = nil, headers = nil)
          run_request(:#{method}, url, nil, headers) do |request|
            request.params.update(params) if params
            yield request if block_given?
          end
        end
      RUBY
    end

    # @!method options(url = nil, params = nil, headers = nil)
    # Makes an OPTIONS HTTP request without a body.
    # @!scope class
    #
    # @param url [String] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param params [Hash] Hash of URI query unencoded key/value pairs.
    # @param headers [Hash] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.options '/items/1'
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]
    def options(*args)
      return @options if args.size.zero?

      url, params, headers = *args
      run_request(:options, url, nil, headers) do |request|
        request.params.update(params) if params
        yield request if block_given?
      end
    end

    # @!method post(url = nil, body = nil, headers = nil)
    # Makes a POST HTTP request with a body.
    # @!scope class
    #
    # @param url [String] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param body [String] body for the request.
    # @param headers [Hash] unencoded HTTP header key/value pairs.
    #
    # @example
    #   conn.post '/items', data, content_type: 'application/json'
    #
    #   # Simple ElasticSearch indexing sample.
    #   conn.post '/twitter/tweet' do |req|
    #     req.headers[:content_type] = 'application/json'
    #     req.params[:routing] = 'kimchy'
    #     req.body = JSON.generate(user: 'kimchy', ...)
    #   end
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]

    # @!method put(url = nil, body = nil, headers = nil)
    # Makes a PUT HTTP request with a body.
    # @!scope class
    #
    # @param url [String] The optional String base URL to use as a prefix for
    #            all requests.  Can also be the options Hash.
    # @param body [String] body for the request.
    # @param headers [Hash] unencoded HTTP header key/value pairs.
    #
    # @example
    #   # TODO: Make it a PUT example
    #   conn.post '/items', data, content_type: 'application/json'
    #
    #   # Simple ElasticSearch indexing sample.
    #   conn.post '/twitter/tweet' do |req|
    #     req.headers[:content_type] = 'application/json'
    #     req.params[:routing] = 'kimchy'
    #     req.body = JSON.generate(user: 'kimchy', ...)
    #   end
    #
    # @yield [Faraday::Request] for further request customizations
    # @return [Faraday::Response]

    # @!visibility private
    METHODS_WITH_BODY.each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(url = nil, body = nil, headers = nil, &block)
          run_request(:#{method}, url, body, headers, &block)
        end
      RUBY
    end

    # Creates a duplicate of this Faraday::Connection.
    #
    # @api private
    #
    # @return [Faraday::Connection]
    def dup
      self.class.new(build_exclusive_url,
                     headers: headers.dup,
                     params: params.dup,
                     builder: builder.dup,
                     ssl: ssl.dup,
                     request: options.dup)
    end

    # Yields username and password extracted from a URI if they both exist.
    #
    # @param uri [URI]
    # @yield [username, password] any username and password
    # @yieldparam username [String] any username from URI
    # @yieldparam password [String] any password from URI
    # @return [void]
    # @api private
    def with_uri_credentials(uri)
      return unless uri.user && uri.password

      yield(Utils.unescape(uri.user), Utils.unescape(uri.password))
    end
  end
end

require 'faraday/connection/authorization_management'
require 'faraday/connection/parallel_management'
require 'faraday/connection/proxy_management'
require 'faraday/connection/request_building'
