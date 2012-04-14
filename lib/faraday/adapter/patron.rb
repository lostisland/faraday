module Faraday
  class Adapter
    class Patron < Faraday::Adapter
      dependency 'patron'

      def initialize(app, &block)
        super(app)
        @block = block if block_given?
      end

      def call(env)
        super

        # TODO: support streaming requests
        env[:body] = env[:body].read if env[:body].respond_to? :read

        session = @session ||= create_session

        if req = env[:request]
          session.timeout = session.connect_timeout = req[:timeout] if req[:timeout]
          session.connect_timeout = req[:open_timeout]              if req[:open_timeout]
                    
          if proxy = req[:proxy]
            session.proxy = proxy[:uri].to_s
            if proxy[:user] && proxy[:password]
              prepend_proxy_auth_string(proxy, session)
            end
          end
        end

        response = begin
          data = env[:body] ? env[:body].to_s : nil
          session.request(env[:method], env[:url].to_s, env[:request_headers], :data => data)
        rescue Errno::ECONNREFUSED
          raise Error::ConnectionFailed, $!
        end

        save_response(env, response.status, response.body, response.headers)

        @app.call env
      rescue ::Patron::TimeoutError => err
        raise Faraday::Error::TimeoutError, err
      end

      if loaded? && defined?(::Patron::Request::VALID_ACTIONS)
        # HAX: helps but doesn't work completely
        # https://github.com/toland/patron/issues/34
        ::Patron::Request::VALID_ACTIONS.tap do |actions|
          actions << :patch unless actions.include? :patch
          actions << :options unless actions.include? :options
        end
      end

      def create_session
        session = ::Patron::Session.new
        @block.call(session) if @block
        session
      end
    end
    
    def prepend_proxy_auth_string(proxy, session)
      session.proxy.insert(7, "#{proxy[:user]}:#{proxy[:password]}@")
    end
  end
end
