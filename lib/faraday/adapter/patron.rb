module Faraday
  class Adapter
    class Patron < Faraday::Adapter
      begin
        require 'patron'
      rescue LoadError, NameError => e
        self.load_error = e
      end

      def call(env)
        super

        # TODO: support streaming requests
        env[:body] = env[:body].read if env[:body].respond_to? :read

        sess = ::Patron::Session.new
        args = [env[:method], env[:url].to_s, env[:request_headers]]
        if Faraday::Connection::METHODS_WITH_BODIES.include?(env[:method])
          args.insert(2, env[:body].to_s)
        end
        resp = sess.send *args

        env.update \
          :status           => resp.status,
          :response_headers => resp.headers.
            inject({}) { |memo, (k, v)| memo.update(k.downcase => v) },
          :body             => resp.body

        @app.call env
      rescue Errno::ECONNREFUSED
        raise Error::ConnectionFailed, $!
      end
    end
  end
end
