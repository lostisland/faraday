require 'addressable/uri'
require 'base64'
require 'set'
require 'faraday/builder'
require 'faraday/request'
require 'faraday/response'
require 'faraday/utils'

module Faraday
  class Connection
    include Addressable

    METHODS = Set.new [:get, :post, :put, :delete, :head, :patch, :options]
    METHODS_WITH_BODIES = Set.new [:post, :put, :patch, :options]

    attr_accessor :host, :port, :scheme, :params, :headers, :parallel_manager
    attr_reader   :path_prefix, :builder, :options, :ssl

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

      self.url_prefix = url if url
      proxy(options[:proxy])

      @params.update options[:params]   if options[:params]
      @headers.update options[:headers] if options[:headers]

      if block_given?
        @builder = Builder.create { |b| yield b }
      else
        @builder = options[:builder] || Builder.new
      end
    end

    def use(klass, *args, &block)
      @builder.use(klass, *args, &block)
    end

    def request(key, *args, &block)
      @builder.request(key, *args, &block)
    end

    def response(key, *args, &block)
      @builder.response(key, *args, &block)
    end

    def adapter(key, *args, &block)
      @builder.adapter(key, *args, &block)
    end

    def build(options = {}, &block)
      @builder.build(options, &block)
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
        builder.lock!
        builder.to_app(lambda { |env|
          # the inner app that creates and returns the Response object
          response = Response.new
          response.finish(env) unless env[:parallel_manager]
          env[:response] = response
        })
      end
    end

    def get(url = nil, headers = nil)
      block = block_given? ? Proc.new : nil
      run_request(:get, url, nil, headers, &block)
    end

    def post(url = nil, body = nil, headers = nil)
      block = block_given? ? Proc.new : nil
      run_request(:post, url, body, headers, &block)
    end

    def put(url = nil, body = nil, headers = nil)
      block = block_given? ? Proc.new : nil
      run_request(:put, url, body, headers, &block)
    end

    def patch(url = nil, body = nil, headers = nil)
      block = block_given? ? Proc.new : nil
      run_request(:patch, url, body, headers, &block)
    end

    def head(url = nil, headers = nil)
      block = block_given? ? Proc.new : nil
      run_request(:head, url, nil, headers, &block)
    end

    def delete(url = nil, headers = nil)
      block = block_given? ? Proc.new : nil
      run_request(:delete, url, nil, headers, &block)
    end

    def basic_auth(login, pass)
      auth = Base64.encode64("#{login}:#{pass}")
      auth.gsub!("\n", "")
      @headers['authorization'] = "Basic #{auth}"
    end

    def token_auth(token, options = {})
      values = ["token=#{token.to_s.inspect}"]
      options.each do |key, value|
        values << "#{key}=#{value.to_s.inspect}"
      end
      # 21 = "Authorization: Token ".size
      comma = ",\n#{' ' * 21}"
      @headers['authorization'] = "Token #{values * comma}"
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

      @proxy =
        case arg
          when String then {:uri => proxy_arg_to_uri(arg)}
          when URI    then {:uri => arg}
          when Hash
            if arg[:uri] = proxy_arg_to_uri(arg[:uri])
              arg
            else
              raise ArgumentError, "no :uri option."
            end
        end
    end

    # Parses the giving url with Addressable::URI and stores the individual
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
      uri              = URI.parse(url)
      self.scheme      = uri.scheme
      self.host        = uri.host
      self.port        = uri.port
      self.path_prefix = uri.path

      @params.merge_query(uri.query)
      basic_auth(uri.user, uri.password) if uri.user && uri.password

      uri
    end

    # Ensures that the path prefix always has a leading / and no trailing /
    def path_prefix=(value)
      if value
        value.chomp!  "/"
        value.replace "/#{value}" if value !~ /^\//
      end
      @path_prefix = value
    end

    def run_request(method, url, body, headers)
      if !METHODS.include?(method)
        raise ArgumentError, "unknown http method: #{method}"
      end

      request = Request.create(method) do |req|
        req.url(url)                if url
        req.headers.update(headers) if headers
        req.body = body             if body
        yield req if block_given?
      end

      env = request.to_env(self)
      self.app.call(env)
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
      uri          = URI.parse(url.to_s)
      if @path_prefix && uri.path !~ /^\//
        new_path = @path_prefix.size > 1 ? @path_prefix.dup : ''
        new_path << "/#{uri.path}" unless uri.path.empty?
        uri.path = new_path
      end
      uri.host   ||= @host
      uri.port   ||= @port
      uri.scheme ||= @scheme

      params = @params.dup.merge_query(uri.query)
      params.update extra_params if extra_params
      uri.query = params.empty? ? nil : params.to_query

      uri
    end

    def dup
      self.class.new(build_url(''), :headers => headers.dup, :params => params.dup, :builder => builder.dup, :ssl => ssl.dup)
    end

    def proxy_arg_to_uri(arg)
      case arg
        when String then URI.parse(arg)
        when URI    then arg
      end
    end
  end
end
