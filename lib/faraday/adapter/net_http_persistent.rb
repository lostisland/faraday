module Faraday
  class Adapter
    class NetHttpPersistent < Faraday::Adapter
      dependency 'net/http/persistent'

      def call(env)
        super
        url  = env[:url]
        req  = env[:request]
        http = Net::HTTP::Persistent.new("#{url.host}:#{url.port}", env[:request][:proxy])

        if url.scheme == 'https' && (ssl = env[:ssl]) && true
          http.verify_mode = ssl[:verify_mode] || begin
            if ssl.fetch(:verify, true)
              # Use the default cert store by default, i.e. system ca certs
              store = OpenSSL::X509::Store.new
              store.set_default_paths
              http.cert_store = store
              OpenSSL::SSL::VERIFY_PEER
            else
              OpenSSL::SSL::VERIFY_NONE
            end
          end

          http.certificate  = ssl[:client_cert]  if ssl[:client_cert]
          http.private_key  = ssl[:client_key]   if ssl[:client_key]
          http.ca_file      = ssl[:ca_file]      if ssl[:ca_file]
          http.cert_store   = ssl[:cert_store]   if ssl[:cert_store]
        end

        http.read_timeout = http.open_timeout = req[:timeout] if req[:timeout]
        http.open_timeout = req[:open_timeout]                if req[:open_timeout]

        if :get != env[:method] || env[:body]
          http_request = Net::HTTPGenericRequest.new \
            env[:method].to_s.upcase,    # request method
            !!env[:body],                # is there request body
            :head != env[:method],       # is there response body
            url.request_uri,             # request uri path
            env[:request_headers]        # request headers

          if env[:body].respond_to?(:read)
            http_request.body_stream = env[:body]
            env[:body] = nil
          elsif env[:body]
            http_request.body = env[:body]
          end
        end

        begin
          http_response = http.request url, http_request
        rescue Errno::ECONNREFUSED
          raise Error::ConnectionFailed, $!
        end

        save_response(env, http_response.code.to_i, http_response.body) do |response_headers|
          http_response.each_header do |key, value|
            response_headers[key] = value
          end
        end

        @app.call env
      rescue Errno::ETIMEDOUT => e1
        raise Faraday::Error::TimeoutError, e1
      rescue Net::HTTP::Persistent::Error => e2
        raise Faraday::Error::TimeoutError, e2 if e2.message.include?("Timeout::Error")
      end

    end
  end
end
