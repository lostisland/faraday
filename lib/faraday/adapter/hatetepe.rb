module Faraday
  class Adapter
    class Hatetepe < Faraday::Adapter
      dependency "hatetepe/client"
      
      def call(env)
        if !EM.reactor_running?
          res = nil
          EM.run_block do
            Fiber.new { res = call env }.resume
          end
          return res
        end
        
        save_response env, 200, "Hello World!" do |headers|
          headers["Content-Length"] = "12"
          headers["Server"] = "hatetepe/0.2.2"
        end
        
        @app.call env
      end
    end
  end
end
