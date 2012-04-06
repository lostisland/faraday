module Faraday
  class Adapter
    class NetHttpPersistent < NetHttpLike
      dependency 'net/http/persistent'

      def create_net_http(env)
        Net::HTTP::Persistent.new("faraday", env[:request][:proxy])
      end

      def call(env)
        super
      rescue Errno::ETIMEDOUT => e1
        raise Faraday::Error::TimeoutError, e1
      rescue Net::HTTP::Persistent::Error => e2
        raise Faraday::Error::TimeoutError, e2 if e2.message.include?("Timeout::Error")
      end

      def perform(http, url, request)
        http.request(url, request)
      end
    end
  end
end
