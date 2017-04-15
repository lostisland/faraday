module Faraday
  class Response::RaiseError < Response::Middleware
    ClientErrorStatuses = 400...600

    def on_complete(env)
      case env[:status]
      when 401
        raise Faraday::Error::Unauthorized, response_values(env)
      when 404
        raise Faraday::Error::ResourceNotFound, response_values(env)
      when 422
        # dont raise error for 422        
      when 407
        # mimic the behavior that we get with proxy requests with HTTPS
        raise Faraday::Error::ConnectionFailed, %{407 "Proxy Authentication Required "}
      when ClientErrorStatuses
        raise Faraday::Error::ClientError, response_values(env)
      end
    end

    def response_values(env)
      {:status => env.status, :headers => env.response_headers, :body => env.body}
    end
  end
end
