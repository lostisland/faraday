module Faraday
  class Request::UrlEncoded < Faraday::Middleware
    def call(env)
      if data = env[:body]
        env[:request_headers]['Content-Type'] = 'application/x-www-form-urlencoded'

        unless data.respond_to?(:to_str)
          env[:body] = Faraday::Utils.build_nested_query data
        end
      end
      @app.call env
    end
  end
end
