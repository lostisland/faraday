# frozen_string_literal: true

module Faraday
  class Adapter
    # Extends Net::HTTP adapter adding methods to configure the request.
    class NetHttp < Faraday::Adapter
      private

      def configure_request(http, req)
        if req[:timeout]
          http.read_timeout = req[:timeout]
          http.open_timeout = req[:timeout]
          if http.respond_to?(:write_timeout=)
            http.write_timeout = req[:timeout]
          end
        end
        http.open_timeout = req[:open_timeout] if req[:open_timeout]
        if req[:write_timeout] && http.respond_to?(:write_timeout=)
          http.write_timeout = req[:write_timeout]
        end
        # Only set if Net::Http supports it, since Ruby 2.5.
        http.max_retries = 0 if http.respond_to?(:max_retries=)

        @config_block&.call(http)
      end

      def configure_ssl(http, ssl)
        http.use_ssl = true
        http.verify_mode = ssl_verify_mode(ssl)
        http.cert_store = ssl_cert_store(ssl)

        http.cert = ssl[:client_cert] if ssl[:client_cert]
        http.key = ssl[:client_key] if ssl[:client_key]
        http.ca_file = ssl[:ca_file] if ssl[:ca_file]
        http.ca_path = ssl[:ca_path] if ssl[:ca_path]
        http.verify_depth = ssl[:verify_depth] if ssl[:verify_depth]
        http.ssl_version = ssl[:version] if ssl[:version]
        http.min_version = ssl[:min_version] if ssl[:min_version]
        http.max_version = ssl[:max_version] if ssl[:max_version]
      end

      def ssl_cert_store(ssl)
        return ssl[:cert_store] if ssl[:cert_store]

        @ssl_cert_store ||= begin
          # Use the default cert store by default, i.e. system ca certs
          OpenSSL::X509::Store.new.tap(&:set_default_paths)
        end
      end

      def ssl_verify_mode(ssl)
        ssl[:verify_mode] || begin
          if ssl.fetch(:verify, true)
            OpenSSL::SSL::VERIFY_PEER
          else
            OpenSSL::SSL::VERIFY_NONE
          end
        end
      end
    end
  end
end
