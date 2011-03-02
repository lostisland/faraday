module Faraday
  class Request::JSON < Faraday::Middleware
    class << self
      attr_accessor :adapter
    end
    
    # loads the JSON encoder either from yajl-ruby or activesupport
    begin
      begin
        require 'yajl'
        self.adapter = Yajl::Encoder
      rescue LoadError, NameError
        require 'active_support/core_ext/module/attribute_accessors' # AS 2.3.11
        require 'active_support/core_ext/kernel/reporting'           # AS 2.3.11
        require 'active_support/json/encoding'
        require 'active_support/ordered_hash' # AS 3.0.4
        self.adapter = ActiveSupport::JSON
      end
    rescue LoadError, NameError => error
      self.load_error = error
    end

    def call(env)
      if data = env[:body]
        env[:request_headers]['Content-Type'] = 'application/json'

        unless data.respond_to?(:to_str)
          env[:body] = self.class.adapter.encode data
        end
      end
      @app.call env
    end
  end
end
