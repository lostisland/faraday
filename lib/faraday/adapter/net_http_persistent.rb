require 'faraday/adapter/net_http'

module Faraday
  class Adapter
    # Experimental adapter for net-http-persistent
    class NetHttpPersistent < NetHttp
      dependency 'net/http/persistent'

      # TODO: investigate is it safe to create a new Persistent instance for
      # every request, or does it defy the purpose of persistent connections
      def net_http_connection(env)
        Net::HTTP::Persistent.new 'Faraday',
          env[:request][:proxy] ? env[:request][:proxy][:uri] : nil
      end

      def perform_request(http, env)
        http.request env[:url], create_request(env)
      rescue Net::HTTP::Persistent::Error => error
        if error.message.include? 'Timeout::Error'
          raise Faraday::Error::TimeoutError, error
        else
          raise
        end
      end

      def configure_ssl(http, ssl)
        http.verify_mode  = ssl_verify_mode(ssl)
        http.cert_store   = ssl_cert_store(ssl)

        http.certificate  = ssl[:client_cert]  if ssl[:client_cert]
        http.private_key  = ssl[:client_key]   if ssl[:client_key]
        http.ca_file      = ssl[:ca_file]      if ssl[:ca_file]
        http.ssl_version  = ssl[:version]      if ssl[:version]
      end
    end
  end
end
