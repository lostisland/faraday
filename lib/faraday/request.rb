# frozen_string_literal: true

module Faraday
  # Used to setup URLs, params, headers, and the request body in a sane manner.
  #
  # @example
  #   @connection.post do |req|
  #     req.url 'http://localhost', 'a' => '1' # 'http://localhost?a=1'
  #     req.headers['b'] = '2' # Header
  #     req.params['c']  = '3' # GET Param
  #     req['b']         = '2' # also Header
  #     req.body = 'abc'
  #   end
  #
  # @!attribute http_method
  #   @return [Symbol] the HTTP method of the Request
  # @!attribute path
  #   @return [URI, String] the path
  # @!attribute params
  #   @return [Hash] query parameters
  # @!attribute headers
  #   @return [Faraday::Utils::Headers] headers
  # @!attribute body
  #   @return [Hash] body
  # @!attribute options
  #   @return [RequestOptions] options
  #
  # rubocop:disable Style/StructInheritance
  class Request < Struct.new(
    :http_method, :path, :params, :headers, :body, :options
  )
    # rubocop:enable Style/StructInheritance

    extend MiddlewareRegistry

    register_middleware File.expand_path('request', __dir__),
                        url_encoded: [:UrlEncoded, 'url_encoded'],
                        multipart: [:Multipart, 'multipart'],
                        retry: [:Retry, 'retry'],
                        authorization: [:Authorization, 'authorization'],
                        basic_auth: [
                          :BasicAuthentication,
                          'basic_authentication'
                        ],
                        token_auth: [
                          :TokenAuthentication,
                          'token_authentication'
                        ],
                        instrumentation: [:Instrumentation, 'instrumentation']

    # @param request_method [String]
    # @yield [request] for block customization, if block given
    # @yieldparam request [Request]
    # @return [Request]
    def self.create(request_method)
      new(request_method).tap do |request|
        yield(request) if block_given?
      end
    end

    def method
      warn <<~TEXT
        WARNING: `Faraday::Request##{__method__}` is deprecated; use `#http_method` instead. It will be removed in or after version 2.0.
        `Faraday::Request##{__method__}` called from #{caller_locations(1..1).first}
      TEXT
      http_method
    end

    # Replace params, preserving the existing hash type.
    #
    # @param hash [Hash] new params
    def params=(hash)
      if params
        params.replace hash
      else
        super
      end
    end

    # Replace request headers, preserving the existing hash type.
    #
    # @param hash [Hash] new headers
    def headers=(hash)
      if headers
        headers.replace hash
      else
        super
      end
    end

    # Update path and params.
    #
    # @param path [URI, String]
    # @param params [Hash, nil]
    # @return [void]
    def url(path, params = nil)
      if path.respond_to? :query
        if (query = path.query)
          path = path.dup
          path.query = nil
        end
      else
        anchor_index = path.index('#')
        path = path.slice(0, anchor_index) unless anchor_index.nil?
        path, query = path.split('?', 2)
      end
      self.path = path
      self.params.merge_query query, options.params_encoder
      self.params.update(params) if params
    end

    # @param key [Object] key to look up in headers
    # @return [Object] value of the given header name
    def [](key)
      headers[key]
    end

    # @param key [Object] key of header to write
    # @param value [Object] value of header
    def []=(key, value)
      headers[key] = value
    end

    # Marshal serialization support.
    #
    # @return [Hash] the hash ready to be serialized in Marshal.
    def marshal_dump
      {
        http_method: http_method,
        body: body,
        headers: headers,
        path: path,
        params: params,
        options: options
      }
    end

    # Marshal serialization support.
    # Restores the instance variables according to the +serialised+.
    # @param serialised [Hash] the serialised object.
    def marshal_load(serialised)
      self.http_method = serialised[:http_method]
      self.body        = serialised[:body]
      self.headers     = serialised[:headers]
      self.path        = serialised[:path]
      self.params      = serialised[:params]
      self.options     = serialised[:options]
    end

    # ENV Keys
    # :http_method - a symbolized request HTTP method (:get, :post)
    # :body   - the request body that will eventually be converted to a string.
    # :url    - URI instance for the current request.
    # :url_prefix - URL prefix from the Connection object.
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
    # @return [Env] the Env for this Request
    def to_env(connection)
      Env.new(
        http_method,
        body,
        connection.build_exclusive_url(path, params, options.params_encoder),
        connection.url_prefix,
        options,
        headers,
        connection.ssl,
        connection.parallel_manager
      )
    end
  end
end
