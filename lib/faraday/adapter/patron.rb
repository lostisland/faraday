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
    end

    # HAX: helps but doesn't work completely
    # https://github.com/toland/patron/issues/34
    valid_actions = ::Patron::Request::VALID_ACTIONS
    valid_actions << :patch unless valid_actions.include? :patch
    valid_actions << :options unless valid_actions.include? :options
  end
end
