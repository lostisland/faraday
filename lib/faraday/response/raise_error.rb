module Faraday
  class Response::RaiseError < Middleware
    ClientErrorStatuses = 400...500
    ServerErrorStatuses = 500...600

    def on_complete(env)
      case env.status
      when 400
        raise Faraday::BadRequestError, response_values(env.response)
      when 401
        raise Faraday::UnauthorizedError, response_values(env.response)
      when 403
        raise Faraday::ForbiddenError, response_values(env.response)
      when 404
        raise Faraday::ResourceNotFound, response_values(env.response)
      when 407
        # mimic the behavior that we get with proxy requests with HTTPS
        raise Faraday::ProxyAuthError.new(%{407 "Proxy Authentication Required"}, response_values(env.response))
      when 422
        raise Faraday::UnprocessableEntityError, response_values(env.response)
      when ClientErrorStatuses
        raise Faraday::ClientError, response_values(env.response)
      when ServerErrorStatuses
        raise Faraday::ServerError, response_values(env.response)
      end
    end

    def response_values(response)
      { :status => response.status, :headers => response.headers, :body => response.body }
    end
  end
end
