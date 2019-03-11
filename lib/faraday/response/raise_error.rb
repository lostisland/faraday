# frozen_string_literal: true

module Faraday
  class Response
    class RaiseError < Middleware
      ClientErrorStatuses = (400...500).freeze
      ServerErrorStatuses = (500...600).freeze

      def on_complete(env)
        case env[:status]
        when 400
          raise Faraday::BadRequestError, response_values(env)
        when 401
          raise Faraday::UnauthorizedError, response_values(env)
        when 403
          raise Faraday::ForbiddenError, response_values(env)
        when 404
          raise Faraday::ResourceNotFound, response_values(env)
        when 407
          # mimic the behavior that we get with proxy requests with HTTPS
          msg = %(407 "Proxy Authentication Required")
          raise Faraday::ProxyAuthError.new(msg, response_values(env))
        when 422
          raise Faraday::UnprocessableEntityError, response_values(env)
        when ClientErrorStatuses
          raise Faraday::ClientError, response_values(env)
        when ServerErrorStatuses
          raise Faraday::ServerError, response_values(env)
        end
      end

      def response_values(env)
        { status: env.status, headers: env.response_headers, body: env.body }
      end
    end
  end
end
