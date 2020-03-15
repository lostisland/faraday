# frozen_string_literal: true

module Faraday
  class Response
    # RaiseError is a Faraday middleware that raises exceptions on common HTTP
    # client or server error responses.
    class RaiseError < Middleware
      # rubocop:disable Naming/ConstantName
      ClientErrorStatuses = (400...500).freeze
      ServerErrorStatuses = (500...600).freeze
      # rubocop:enable Naming/ConstantName

      def on_complete(env)
        case env[:status]
        when 400
          raise Faraday::BadRequestError
            .new(response_values(env), nil, env.response)
        when 401
          raise Faraday::UnauthorizedError
            .new(response_values(env), nil, env.response)
        when 403
          raise Faraday::ForbiddenError
            .new(response_values(env), nil, env.response)
        when 404
          raise Faraday::ResourceNotFound
            .new(response_values(env), nil, env.response)
        when 407
          # mimic the behavior that we get with proxy requests with HTTPS
          msg = %(407 "Proxy Authentication Required")
          raise Faraday::ProxyAuthError
            .new(msg, response_values(env), env.response)
        when 409
          raise Faraday::ConflictError
            .new(response_values(env), nil, env.response)
        when 422
          raise Faraday::UnprocessableEntityError
            .new(response_values(env), nil, env.response)
        when ClientErrorStatuses
          raise Faraday::ClientError
            .new(response_values(env), nil, env.response)
        when ServerErrorStatuses
          raise Faraday::ServerError
            .new(response_values(env), nil, env.response)
        when nil
          raise Faraday::NilStatusError, response_values(env)
        end
      end

      def response_values(env)
        { status: env.status, headers: env.response_headers, body: env.body }
      end
    end
  end
end
