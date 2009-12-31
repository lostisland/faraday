module Faraday
  module Request
    class PostRequest
      extend Loadable

      def initialize params
        @params = params
      end

      def encode
        create_post_params @params
      end
    
     private
      def create_post_params(params, base = "")
        [].tap do |toreturn|
          params.each_key do |key|
            keystring = base == '' ? key : "#{base}[#{key}]"
            toreturn << (params[key].kind_of?(Hash) ? create_post_params(params[key], keystring) : "#{keystring}=#{CGI.escape(params[key].to_s)}")
          end
        end.join('&')
      end
    end
  end
end
