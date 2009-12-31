require 'addressable/uri'
module Faraday
  class Connection
    module Options
      def load_error()       @load_error         end
      def load_error=(v)     @load_error = v     end
      def supports_async()   @supports_async     end
      def supports_async=(v) @supports_async = v end
      def loaded?()         !@load_error         end
      alias supports_async? supports_async
    end

    include Addressable

    attr_accessor :host, :port, :scheme
    attr_reader   :path_prefix

    def initialize(url = nil)
      @response_class = nil
      @request_class  = nil
      self.url_prefix = url if url
    end

    def url_prefix=(url)
      uri              = URI.parse(url)
      self.scheme      = uri.scheme
      self.host        = uri.host
      self.port        = uri.port
      self.path_prefix = uri.path
    end

    def encode_params data
      request_class.new(data).encode
    end

    # Override in a subclass, or include an adapter
    #
    #   def _get(uri, headers)
    #   end
    #
    def get(uri, params = {}, headers = {})
      _get build_uri(uri, params), headers
    end

    # Override in a subclass, or include an adapter
    #
    #   def _post(uri, post_params, headers)
    #   end
    #
    def post(uri, params = {}, headers = {})
      _post build_uri(uri), params, headers
    end

    # Override in a subclass, or include an adapter
    #
    #   def _put(uri, post_params, headers)
    #   end
    #
    def put(uri, params = {}, headers = {})
      _put build_uri(uri), params, headers
    end

    def delete(uri, params = {}, headers = {})
      _delete build_uri(uri, params), headers
    end

    def request_class
      @request_class || Request::PostRequest
    end

    def response_class
      @response_class || Response
    end

    def response_class=(v)
      if v.respond_to?(:loaded?) && !v.loaded?
        raise ArgumentError, "The response class: #{v.inspect} does not appear to be loaded."
      end
      @response_class = v
    end

    def request_class=(v)
      if v.respond_to?(:loaded?) && !v.loaded?
        raise ArgumentError, "The request class: #{v.inspect} does not appear to be loaded."
      end
      @request_class = v
    end

    def in_parallel?
      !!@parallel_manager
    end

    def in_parallel(options = {})
      @parallel_manager = true
      yield
      @parallel_manager = false
    end

    def setup_parallel_manager(options = {})
    end

    def run_parallel_requests
    end

    def path_prefix=(value)
      if value
        value.chomp!  "/"
        value.replace "/#{value}" if value !~ /^\//
      end
      @path_prefix = value
    end

    def build_uri(url, params = {})
      uri          = URI.parse(url)
      uri.scheme ||= @scheme
      uri.host   ||= @host
      uri.port   ||= @port
      if @path_prefix && uri.path !~ /^\//
        uri.path = "#{@path_prefix.size > 1 ? @path_prefix : nil}/#{uri.path}"
      end
      query = params_to_query(params)
      if !query.empty? then uri.query = query end
      uri
    end

    def params_to_query(params)
      params.inject([]) do |memo, (key, val)|
        memo << "#{escape_for_querystring(key)}=#{escape_for_querystring(val)}"
      end.join("&")
    end

    # Some servers convert +'s in URL query params to spaces.
    # Go ahead and encode it.
    def escape_for_querystring(s)
      URI.encode_component(s, Addressable::URI::CharacterClasses::QUERY).tap do |escaped|
        escaped.gsub! /\+/, "%2B"
      end
    end
  end
end
