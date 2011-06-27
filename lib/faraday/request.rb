module Faraday
  # Used to setup urls, params, headers, and the request body in a sane manner.
  #
  #   @connection.post do |req|
  #     req.url 'http://localhost', 'a' => '1' # 'http://localhost?a=1'
  #     req.headers['b'] = '2' # Header
  #     req.params['c']  = '3' # GET Param
  #     req['b']         = '2' # also Header
  #     req.body = 'abc'
  #   end
  #
  class Request < Struct.new(:path, :params, :headers, :body, :options)
    extend AutoloadHelper

    autoload_all 'faraday/request',
      :JSON       => 'json',
      :UrlEncoded => 'url_encoded',
      :Multipart  => 'multipart'

    register_lookup_modules \
      :json        => :JSON,
      :url_encoded => :UrlEncoded,
      :multipart   => :Multipart

    attr_reader :method

    def self.create(request_method)
      new(request_method).tap do |request|
        yield request if block_given?
      end
    end

    def initialize(request_method)
      @method = request_method
      self.params  = {}
      self.headers = {}
      self.options = {}
    end

    def url(path, params = {})
      self.path   = path
      self.params = params
    end

    def [](key)
      headers[key]
    end

    def []=(key, value)
      headers[key] = value
    end

    # ENV Keys
    # :method - a symbolized request method (:get, :post)
    # :body   - the request body that will eventually be converted to a string.
    # :url    - Addressable::URI instance of the URI for the current request.
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
    def to_env(connection)
      env_params  = connection.params.merge(params)
      env_headers = connection.headers.merge(headers)
      request_options = Utils.deep_merge(connection.options, options)
      Utils.deep_merge!(request_options, :proxy => connection.proxy)

      { :method           => method,
        :body             => body,
        :url              => connection.build_url(path, env_params),
        :request_headers  => env_headers,
        :parallel_manager => connection.parallel_manager,
        :request          => request_options,
        :ssl              => connection.ssl}
    end
  end
end
