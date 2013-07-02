module Faraday
  class Response::RaiseError < Response::Middleware
    ClientErrorStatuses = 400...600

    def on_complete(env)
      case env[:status]
      when 404
        raise Faraday::Error::ResourceNotFound, response_values(env)
      when 422
        #raise Faraday::Error::UnprocessableEntity, response_values(env)
      when ClientErrorStatuses
        raise Faraday::Error::ClientError, response_values(env)
      end
    end

    def response_values(env)
      {:status => env.status, :headers => env.response_headers, :body => env.body}
    end
  end
end
