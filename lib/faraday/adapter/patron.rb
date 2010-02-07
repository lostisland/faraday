module Faraday
  module Adapter
    class Patron < Middleware
      begin
        require 'patron'
      rescue LoadError, NameError => e
        self.load_error = e
      end

      def call(env)
        process_body_for_request(env)

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
        env[:response].finish(env)

        @app.call env
      rescue Errno::ECONNREFUSED
        raise Error::ConnectionFailed, "connection refused"
      end
    end
  end
end
