module Faraday
  class Adapter
    class Hatetepe < Faraday::Adapter
      dependency "hatetepe/client"
      
      def call(env)
        if !EM.reactor_running?
          res = nil
          EM.synchrony do
            begin
              res = call(env)
            ensure
              EM.stop
            end
          end
          return res
        end
        
        args = env.values_at(:method, :url, :request_headers, :body)
        response = ::Hatetepe::Client.request(*args)
        
        save_response env, response.status, response.body.read do |headers|
          response.headers.each do |k, v|
            headers[k] = v
          end
        end
        
        @app.call env
      end
    end
  end
end
