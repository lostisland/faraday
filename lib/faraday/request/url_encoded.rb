module Faraday
  class Request::UrlEncoded < Faraday::Middleware
    class << self
      attr_accessor :mime_type
    end
    
    self.mime_type = 'application/x-www-form-urlencoded'.freeze

    def call(env)
      match_content_type(env) do |data|
        env[:body] = Faraday::Utils.build_nested_query data
      end
      @app.call env
    end
    
    def match_content_type(env)
      type = request_type(env)
      
      if env[:body] and (type.empty? or type == self.class.mime_type)
        env[:request_headers]['Content-Type'] ||= self.class.mime_type
        yield env[:body] unless env[:body].respond_to?(:to_str)
      end
    end
    
    def request_type(env)
      type = env[:request_headers]['Content-Type'].to_s
      type = type.split(';', 2).first if type.index(';')
      type
    end
  end
end
