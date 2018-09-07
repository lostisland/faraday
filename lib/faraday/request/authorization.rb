module Faraday
  # Request middleware for the Authorization HTTP header
  class Request::Authorization < Faraday::Middleware
    KEY = "Authorization".freeze unless defined? KEY

    # @param type [String, Symbol]
    # @param token [String, Symbol, Hash]
    # @return [String] a header value
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

    # @param type [String]
    # @param hash [Hash]
    # @return [String] type followed by comma-separated key=value pairs
    # @api private
    def self.build_hash(type, hash)
      comma = ", "
      values = []
      hash.each do |key, value|
        values << "#{key}=#{value.to_s.inspect}"
      end
      "#{type} #{values * comma}"
    end

    # @param app [#call]
    # @param type [String, Symbol] Type of Authorization
    # @param token [String, Symbol, Hash] Token value for the Authorization
    def initialize(app, type, token)
      @header_value = self.class.header(type, token)
      super(app)
    end

    # @param env [Faraday::Env]
    def call(env)
      unless env.request_headers[KEY]
        env.request_headers[KEY] = @header_value
      end
      @app.call(env)
    end
  end
end

