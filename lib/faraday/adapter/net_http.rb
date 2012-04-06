begin
  require 'net/https'
rescue LoadError
  warn "Warning: no such file to load -- net/https. Make sure openssl is installed if you want ssl support"
  require 'net/http'
end

module Faraday
  class Adapter
    class NetHttpLike < Faraday::Adapter # :nodoc:
      def setup_ssl(http, options)
        http.verify_mode = options[:verify_mode] || begin
          if options.fetch(:verify, true)
            # Use the default cert store by default, i.e. system ca certs
            store = OpenSSL::X509::Store.new
            store.set_default_paths
            http.cert_store = store
            OpenSSL::SSL::VERIFY_PEER
          else
            OpenSSL::SSL::VERIFY_NONE
          end
        end

        http.cert         = options[:client_cert]  if options[:client_cert]
        http.key          = options[:client_key]   if options[:client_key]
        http.ca_file      = options[:ca_file]      if options[:ca_file]
        http.ca_path      = options[:ca_path]      if options[:ca_path]
        http.cert_store   = options[:cert_store]   if options[:cert_store]
        http.verify_depth = options[:verify_depth] if options[:verify_depth]
      end

      def create_request(env)
        req = Net::HTTPGenericRequest.new \
          env[:method].to_s.upcase,    # request method
          !! env[:body],               # is there request body
          :head != env[:method],       # is there response body
          env[:url].request_uri,       # request uri path
          env[:request_headers]        # request headers

        if env[:body]
          if env[:body].respond_to?(:read)
            req.body_stream = env[:body]
          else
            req.body = env[:body]
          end
        end

        req
      end

      def call(env)
        super

        url = env[:url]
        req = env[:request]

        http = create_net_http(env)

        if url.scheme == 'https' && env[:ssl]
          setup_ssl(http, env[:ssl])
        end

        http.read_timeout = http.open_timeout = req[:timeout] if req[:timeout]
        http.open_timeout = req[:open_timeout]                if req[:open_timeout]

        request = create_request(env)

        begin
          res = perform(http, url, request)
        rescue Errno::ECONNREFUSED
          raise Error::ConnectionFailed, $!
        end

        save_response(env, res.code.to_i, res.body) do |response_headers|
          res.each_header do |key, value|
            response_headers[key] = value
          end
        end

        @app.call(env)
      rescue Timeout::Error => err
        raise Faraday::Error::TimeoutError, err
      end
    end

    class NetHttp < NetHttpLike
      def setup_ssl(http, options)
        http.use_ssl = true
        super
      end

      def create_net_http(env)
        klass = if proxy = env[:request][:proxy]
          Net::HTTP::Proxy(proxy[:uri].host, proxy[:uri].port, proxy[:user], proxy[:password])
        else
          Net::HTTP
        end

        klass.new(env[:url].host, env[:url].port)
      end

      def perform(http, url, request)
        if request.method == "GET" and !request.request_body_permitted?
          # prefer `get` to `request` because the former handles gzip (ruby 1.9)

          headers = request.to_hash

          headers.each do |key, value|
            headers[key] = value.first
          end

          http.get(url.request_uri, headers)
        else
          http.request(request)
        end
      end
    end
  end
end
