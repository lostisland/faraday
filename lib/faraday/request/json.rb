module Faraday
  class Request::JSON < Request::UrlEncoded
    self.mime_type = 'application/json'.freeze

    dependency "multi_json"

    def call(env)
      match_content_type(env) do |data|
        env[:body] = MultiJson.encode data
      end
      @app.call env
    end
  end
end
