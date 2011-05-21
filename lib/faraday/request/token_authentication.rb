module Faraday
  class Request::TokenAuthentication < Faraday::Middleware
    def initialize(app, token, options={})
      super(app)

      values = ["token=#{token.to_s.inspect}"]
      options.each do |key, value|
        values << "#{key}=#{value.to_s.inspect}"
      end
      comma = ",\n#{' ' * ('Authorization: Token '.size)}"
      @header_value = "Token #{values * comma}"
    end

    def call(env)
      env[:request_headers]['Authorization'] = @header_value
      @app.call(env)
    end
  end
end