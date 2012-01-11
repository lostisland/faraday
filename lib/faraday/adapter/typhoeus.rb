module Faraday
  class Adapter
    class Typhoeus < Faraday::Adapter
      self.supports_parallel_requests = true

      def self.setup_parallel_manager(options = {})
        options.empty? ? ::Typhoeus::Hydra.hydra : ::Typhoeus::Hydra.new(options)
      end

      dependency 'typhoeus'

      def call(env)
        super
        perform_request env
        @app.call env
      end

      def perform_request(env)
        read_body_on env

        hydra = env[:parallel_manager] || self.class.setup_parallel_manager
        hydra.queue request(env)
        hydra.run unless parallel?(env)
      rescue Errno::ECONNREFUSED
        raise Error::ConnectionFailed, $!
      end

      # TODO: support streaming requests
      def read_body_on(env)
        env[:body] = env[:body].read if env[:body].respond_to? :read
      end

      def request(env)
        req = ::Typhoeus::Request.new env[:url].to_s,
          :method  => env[:method],
          :body    => env[:body],
          :headers => env[:request_headers],
          :disable_ssl_peer_verification => (env[:ssl] && !env[:ssl].fetch(:verify, true))

        configure_ssl_on     req, env
        configure_proxy_on   req, env
        configure_timeout_on req, env

        req.on_complete do |resp|
          save_response(env, resp.code, resp.body) do |response_headers|
            response_headers.parse resp.headers
          end
          # in async mode, :response is initialized at this point
          env[:response].finish(env) if parallel?(env)
        end

        req
      end

      def configure_ssl_on(req, env)
        ssl = env[:ssl]

        req.ssl_cert   = ssl[:client_cert_file] if ssl[:client_cert_file]
        req.ssl_key    = ssl[:client_key_file]  if ssl[:client_key_file]
        req.ssl_cacert = ssl[:ca_file]          if ssl[:ca_file]
        req.ssl_capath = ssl[:ca_path]          if ssl[:ca_path]
      end

      def configure_proxy_on(req, env)
        proxy = env[:request][:proxy]
        return unless proxy

        req.proxy = "#{proxy[:uri].host}:#{proxy[:uri].port}"

        if proxy[:username] && proxy[:password]
          req.proxy_username = proxy[:username]
          req.proxy_password = proxy[:password]
        end
      end

      def configure_timeout_on(req, env)
        env_req = env[:request]
        req.timeout = req.connect_timeout = (env_req[:timeout] * 1000) if env_req[:timeout]
        req.connect_timeout = (env_req[:open_timeout] * 1000)          if env_req[:open_timeout]
      end

      def parallel?(env)
        !!env[:parallel_manager]
      end
    end
  end
end
