module Faraday
  class Adapter
    class HttpGem < Faraday::Adapter
      dependency 'http'

      def initialize(app, options = {})
        @client = ::HTTP::Client.new options
        super(app)
      end

      def call(env)
        super

        # TODO: Support streaming.
        #   HTTP gem expects body to be String or Enumerable,
        env[:body] = env[:body].read if env[:body].respond_to? :read

        begin
          res = @client.request(env[:method], env[:url], {
              :body => env[:body],
              :headers => env[:request_headers],
              :proxy => proxy_options(env)
            }.merge(socket_options(env)))
        rescue HTTP::ConnectionError => e
          raise Faraday::Error::ConnectionFailed, e
        rescue OpenSSL::SSL::SSLError => e
          raise Faraday::SSLError, e
        end

        save_response env, res.status, res.to_s, res.headers.to_h

        @app.call env
      end

      private

      def proxy_options(env)
        return unless env[:request][:proxy]

        rv = {
          :proxy_address => env[:request][:proxy][:uri].host,
          :proxy_port    => env[:request][:proxy][:uri].port
        }

        if env[:request][:proxy][:user]
          rv[:proxy_username] = env[:request][:proxy][:user]
          rv[:proxy_password] = env[:request][:proxy][:password]
        end

        rv
      end

      def socket_options(env)
        rv = {}

        if env[:url].scheme == 'https' && ssl = env[:ssl]
          ctx      = OpenSSL::SSL::SSLContext.new

          ctx.verify_mode  = ssl_verify_mode(ssl)
          ctx.cert_store   = ssl_cert_store(ssl)

          ctx.cert         = ssl[:client_cert]  if ssl[:client_cert]
          ctx.key          = ssl[:client_key]   if ssl[:client_key]
          ctx.ca_file      = ssl[:ca_file]      if ssl[:ca_file]
          ctx.ca_path      = ssl[:ca_path]      if ssl[:ca_path]
          ctx.verify_depth = ssl[:verify_depth] if ssl[:verify_depth]
          ctx.ssl_version  = ssl[:version]      if ssl[:version]

          rv.merge!(:ssl_context => ctx)
        end

        rv
      end

      def ssl_cert_store(ssl)
        return ssl[:cert_store] if ssl[:cert_store]
        # Use the default cert store by default, i.e. system ca certs
        cert_store = OpenSSL::X509::Store.new
        cert_store.set_default_paths
        cert_store
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