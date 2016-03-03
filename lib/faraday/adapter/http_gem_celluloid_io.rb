# I wonder why autoloading does not work
require 'faraday/adapter/http_gem'

module Faraday
  class Adapter
    class HttpGemCelluloidIO < HttpGem

      dependency 'http'
      dependency 'celluloid/io'


      private

      def socket_options(env)
        rv = super(env)
        
        if env[:url].scheme == 'https' && ssl = env[:ssl]
          rv.merge!( :ssl_socket_class => Celluloid::IO::SSLSocket )
        else
          rv.merge!( :socket_class => Celluloid::IO::TCPSocket )
        end

        rv
      end

    end
  end
end