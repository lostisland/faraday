module Faraday
  class Adapter
    class ApiAuth < Faraday::Adapter
      dependency 'api-auth'

      # possible => data
      #  verify_mode

      # TODO documentation
      def initialize(app, access_id, secret_key, data = {})
        super(app)

        @access_id  = access_id
        @secret_key = secret_key
      end

      # TODO documentation
      def call(env)
        super

        http_response = request(env[:url], env[:method], env[:body])

        save_response(env, http_response.code.to_i, http_response.body || '') do |response_headers|
          http_response.each_header do |key, value|
            response_headers[key] = value
          end
        end

        @app.call(env)
      end

      private

      # TODO documentation
      def request(uri, method, data = {})
        http    = Net::HTTP.new(uri.host, uri.port)
        request = request_for_http_method(method, uri)

        data.present? ? request.set_form_data(data) : request['Content-Length'] = 0

        signed_request = ::ApiAuth.sign!(request, @access_id, @secret_key)
        http.use_ssl     = uri.scheme.eql?('https')
        http.verify_mode = false

        http.request(signed_request)
      end

      # TODO documentation
      def request_for_http_method(method, uri)
        case method
          when :post
            Net::HTTP::Post.new(uri.request_uri)
          when :put
            Net::HTTP::Put.new(uri.request_uri)
          when :get
            Net::HTTP::Get.new(uri.request_uri)
          when :delete
            Net::HTTP::Delete.new(uri.request_uri)
        end
      end
    end
  end
end

