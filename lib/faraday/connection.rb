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

    attr_accessor :host, :port, :scheme, :params, :headers
    attr_reader   :path_prefix

    # :url
    # :params
    # :headers
    # :response
    def initialize(url = nil, options = {})
      if url.is_a?(Hash)
        options = url
        url     = options[:url]
      end
      @response_class = options[:response]
      @params         = options[:params]  || {}
      @headers        = options[:headers] || {}
      self.url_prefix = url if url
    end

    def url_prefix=(url)
      uri              = URI.parse(url)
      self.scheme      = uri.scheme
      self.host        = uri.host
      self.port        = uri.port
      self.path_prefix = uri.path
    end

    # Override in a subclass, or include an adapter
    #
    #   def _get(uri, headers)
    #   end
    #
    def get(url, params = nil, headers = nil)
      uri = build_uri(url, build_params(params))
      _get(uri, build_headers(headers))
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

    def build_uri(url, params = nil)
      uri          = URI.parse(url)
      uri.scheme ||= @scheme
      uri.host   ||= @host
      uri.port   ||= @port
      if @path_prefix && uri.path !~ /^\//
        uri.path = "#{@path_prefix.size > 1 ? @path_prefix : nil}/#{uri.path}"
      end
      if params && !params.empty?
        uri.query = params_to_query(params)
      end
      uri
    end

    def path_for(uri)
      uri.path.tap do |s|
        s << "?#{uri.query}"    if uri.query
        s << "##{uri.fragment}" if uri.fragment
      end
    end

    def build_params(existing)
      build_hash :params, existing
    end

    def build_headers(existing)
      build_hash(:headers, existing).tap do |headers|
        headers.keys.each do |key|
          headers[key] = headers.delete(key).to_s
        end
      end
    end

    def build_hash(method, existing)
      existing ? send(method).merge(existing) : send(method)
    end

    def params_to_query(params)
      params.inject([]) do |memo, (key, val)|
        memo << "#{escape_for_querystring(key)}=#{escape_for_querystring(val)}"
      end.join("&")
    end

    # Some servers convert +'s in URL query params to spaces.
    # Go ahead and encode it.
    def escape_for_querystring(s)
      URI.encode_component(s.to_s, Addressable::URI::CharacterClasses::QUERY).tap do |escaped|
        escaped.gsub! /\+/, "%2B"
      end
    end
  end
end
