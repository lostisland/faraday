module Faraday
  class Request::Authorization < Faraday::Middleware
    KEY = "Authorization".freeze

    # Public
    def self.header(type, token)
      case token
      when String, Symbol then "#{type} #{token}"
      when Hash then build_hash(type.to_s, token)
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

    def initialize(app, type, token)
      @header_value = self.class.header(type, token)
      super(app)
    end

    # Public
    def call(env)
      unless env[:request_headers][KEY]
        env[:request_headers][KEY] = @header_value
      end
      @app.call(env)
    end
  end
end

