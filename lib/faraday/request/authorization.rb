module Faraday
  class Request::Authorization < Faraday::Middleware
    KEY = "Authorization".freeze unless defined? KEY

    # Public
    def self.header(type, token)
      case token
      when String, Symbol
        "#{type} #{token}"
      when Hash
        build_hash(type.to_s, token)
      else
        raise ArgumentError, "Can't build an Authorization #{type} header from #{token.inspect}"
      end
    end

    # Internal
    def self.build_hash(type, hash)
      offset = KEY.size + type.size + 3
      comma = ",\n#{' ' * offset}"
      values = []
      hash.each do |key, value|
        values << "#{key}=#{value.to_s.inspect}"
      end
      "#{type} #{values * comma}"
    end

    def initialize(app, type, token, origin = nil)
      @header_value = self.class.header(type, token)
      if origin
        uri = URI(origin)
        URI::HTTP === uri && uri.host or
          raise ArgumentError, "origin must be an absolute HTTP URL: #{origin.inspect}"
        uri.path = '/' if uri.path.empty?
        @origin = uri
      else
        @origin = nil
      end
      super(app)
    end

    # Public
    def call(env)
      if !env.request_headers[KEY] && under_origin?(env[:url])
        env.request_headers[KEY] = @header_value
      end
      @app.call(env)
    end

    private

    def under_origin?(uri)
      return true unless @origin

      uri.scheme == @origin.scheme &&
        uri.port == @origin.port &&
        # DomainName(uri.host) == DomainName(@origin.host) &&
        uri.host.casecmp(@origin.host) == 0 &&
        path_match?(@origin.path, uri.path)
    end

    def path_match?(base_path, target_path)
      # Implementation taken from http-cookie
      base_path.start_with?('/') or return false
      # RFC 6265 5.1.4
      bsize = base_path.size
      tsize = target_path.size
      return bsize == 1 if tsize == 0 # treat empty target_path as "/"
      return false unless target_path.start_with?(base_path)
      return true if bsize == tsize || base_path.end_with?('/')
      target_path[bsize] == ?/
    end
  end
end

