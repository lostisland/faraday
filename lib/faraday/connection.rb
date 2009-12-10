require 'addressable/uri'
module Faraday
  class Connection
    include Addressable

    attr_accessor :host, :port
    attr_reader :path_prefix

    def initialize(url = nil)
      if url
        uri          = URI.parse(url)
        @host        = uri.host
        @port        = uri.port
        @path_prefix = uri.path if !uri.path.empty?
      end
    end

    def get(url, params = {}, headers = {})
      _get(build_uri(url, params), headers)
    end

    def path_prefix=(value)
      if value
        value.chomp! "/"
        value.replace "/#{value}" if value !~ /^\//
      end
      @path_prefix = value
    end

    def build_uri(url, params = {})
      uri         = URI.parse(url)
      uri.host  ||= @host
      uri.port  ||= @port
      if @path_prefix && uri.path !~ /^\//
        uri.path = "#{@path_prefix}/#{uri.path}"
      end
      uri.query   = params_to_query(params)
      uri
    end

    def params_to_query(params)
      params.inject([]) do |memo, (key, val)|
        memo << "#{URI.escape(key)}=#{URI.escape(val)}"
      end.join("&")
    end

    def _get(uri, headers)
      raise NotImplementedError
    end
  end
end