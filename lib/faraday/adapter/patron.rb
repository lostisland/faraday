module Faraday
  class Adapter
    class Patron < Faraday::Adapter
      dependency 'patron'

      def call(env)
        super

        # TODO: support streaming requests
        env[:body] = env[:body].read if env[:body].respond_to? :read

        session = ::Patron::Session.new

        response = begin
          data = Connection::METHODS_WITH_BODIES.include?(env[:method]) ? env[:body].to_s : nil
          session.request(env[:method], env[:url].to_s, env[:request_headers], :data => data)
        rescue Errno::ECONNREFUSED
          raise Error::ConnectionFailed, $!
        end

        save_response(env, response.status, response.body, response.headers)

        @app.call env
      end

      if loaded? && defined?(::Patron::Request::VALID_ACTIONS)
        # HAX: helps but doesn't work completely
        # https://github.com/toland/patron/issues/34
        ::Patron::Request::VALID_ACTIONS.tap do |actions|
          actions << :patch unless actions.include? :patch
          actions << :options unless actions.include? :options
        end
      end
    end
  end
end
