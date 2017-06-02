module Faraday
  class Adapter

    # Adapter for the HTTP.rb gem: https://rubygems.org/gems/http
    #
    # You can initialize the adapter with any of the options
    # that the gem allows
    #
    # Examples
    #
    #   Faraday.new do |faraday|
    #     faraday.adapter :http, :keep_alive_timeout => 10
    #   end
    #
    # See the class HTTP::Options for a complete list.
    class HTTP < Faraday::Adapter
      dependency 'http'

      # This class handles all SSL composition in one place.
      class SSL

        # Public: Initializes a new SSL instance.
        #
        # env - The Faraday::Env for the current request.
        def initialize(env)
          @env = env
        end

        # Public: Gets the SSL options.
        #
        # See the method context.
        #
        # Returns a Hash with the key :ssl_context or empty if
        # there is no context available.
        def to_h
          ctx = context

          ctx ? { :ssl_context => ctx } : {}
        end
        alias_method :to_hash, :to_h

        # Public: Gets the SSLContext from the request env.
        #
        # Returns a OpenSSL::SSL::SSLContext or NilClass if
        # the env doesn't have SSL information.
        def context
          return unless @env[:url].scheme == 'https' && @env[:ssl]

          ssl = @env[:ssl]
          ctx = OpenSSL::SSL::SSLContext.new

          ctx.verify_mode  = verify_mode(ssl)
          ctx.cert_store   = cert_store(ssl)

          ctx.cert         = ssl[:client_cert]  if ssl[:client_cert]
          ctx.key          = ssl[:client_key]   if ssl[:client_key]
          ctx.ca_file      = ssl[:ca_file]      if ssl[:ca_file]
          ctx.ca_path      = ssl[:ca_path]      if ssl[:ca_path]
          ctx.verify_depth = ssl[:verify_depth] if ssl[:verify_depth]
          ctx.ssl_version  = ssl[:version]      if ssl[:version]

          ctx
        end

        private

        # Private: Gets the certificate storage item from the env.
        #
        # ssl - The Hash with SSL options from the env.
        #
        # Returns a OpenSSL::X509::Store instance or the
        # contents of the ssl[:cert_store] key.
        def cert_store(ssl)
          return ssl[:cert_store] if ssl[:cert_store]

          cert_store = OpenSSL::X509::Store.new
          cert_store.set_default_paths
          cert_store
        end

        # Private: Gets the SSL verification mode.
        #
        # You can disable any verification with the
        # option env[:ssl][:verify] set to false.
        #
        # ssl - The Hash with SSL options from the env.
        #
        # Returns a OpenSSL::SSL::VERIFY_* mode or the
        # contents of the ssl[:verify_mode] key.
        def verify_mode(ssl)
          return ssl[:verify_mode] if ssl[:verify_mode]

          if ssl.fetch(:verify, true)
            OpenSSL::SSL::VERIFY_PEER
          else
            OpenSSL::SSL::VERIFY_NONE
          end
        end
      end

      # Public: Initializes a new instance of the adapter.
      #
      # app     - Current Faraday middleware.
      # options - The optional Hash with options for the HTTP::Client class.
      def initialize(app, options = {})
        @app = app
        @options = options
      end

      # Public: Executes the request using HTTP.rb gem.
      #
      # env - The Faraday::Env instance for the request.
      #
      # Returns a Faraday::Env with the results of the request.
      def call(env)
        handle_errors do
          super
          req = env[:request]

          http = build_client(env)
          http = proxy(http, req)
          http = timeout(http, req)
          http = headers(http, env)

          body = read_body(env)
          response = http.request(env[:method], env[:url], :body => body)

          status, headers, body = response.to_a

          save_response(env, status, body, headers)

          @app.call env
        end
      end

      private

      # Private: Controls possible errors during the request and
      # raises the equivalent Faraday::Error instances.
      #
      # Raises Faraday::SSLError if there is a problem with SSL connections.
      # Raises Faraday::Error::TimeoutError on timeouts.
      # Raises Faraday::Error::ConnectionFailed on any other kind of error.
      def handle_errors
        yield
      rescue OpenSSL::SSL::SSLError => error
        raise SSLError, error
      rescue ::HTTP::TimeoutError => error
        raise Error::TimeoutError, error
      rescue ::HTTP::Error => error
        raise Error::ConnectionFailed, error
      end

      # Private: Gets the HTTP::Client that will handle the request.
      #
      # This client is initialized with the adapter options and any SSL context.
      #
      # Returns an HTTP::Client instance.
      def build_client(env)
        ::HTTP::Client.new @options.merge(SSL.new(env).to_h)
      end

      # Private: Sets the proxy information in the http client.
      #
      # http - The current HTTP::Client.
      # req  - The current Faraday::Request.
      #
      # Returns a HTTP::Client with proxy information or the same client if there is no
      # proxy to configure.
      def proxy(http, req)
        return http unless req[:proxy]

        host = req[:proxy][:uri].hostname
        port = req[:proxy][:uri].port
        user = req[:proxy][:user]
        pass = req[:proxy][:password]

        http.via(host, port, user, pass)
      end

      # Private: Sets the timeout information in the http client.
      #
      # http - The current HTTP::Client.
      # req  - The current Faraday::Request.
      #
      # Returns a HTTP::Client with timeout information or the same client if there is no
      # timeout to configure.
      def timeout(http, req)
        return http unless req[:timeout] || req[:open_timeout]

        options = {}

        if req[:timeout]
          options[:read]    = req[:timeout]
          options[:connect] = req[:timeout]
          options[:write]   = req[:timeout]
        end

        if req[:open_timeout]
          options[:connect] = req[:open_timeout]
          options[:write]   = req[:open_timeout]
        end

        http.timeout(options)
      end

      # Private: Sets the headers in the http client.
      #
      # http - The current HTTP::Client.
      # env  - The current Faraday::Env.
      #
      # Returns a HTTP::Client with headers or the same client if there is no
      # headers to set.
      def headers(http, env)
        return http unless env[:request_headers]

        http.headers(env[:request_headers])
      end

      # Private: Gets the body of the request from the env.
      #
      # This method handles special cases like file uploads with
      # bodies that respond to #read.
      #
      # Note that HTTP handles streaming with body objects that
      # respond to the #each method.
      #
      # env - The current Faraday::Env.
      #
      # Returns a String with the contents of the env[:body] or the
      # instance that represents the env[:body]
      def read_body(env)
        env[:body].respond_to?(:read) ? env[:body].read : env[:body]
      end
    end
  end
end
