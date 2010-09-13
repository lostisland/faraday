module Faraday
  class Response::Nokogiri < Faraday::Response::Middleware
    begin
      require 'nokogiri'

      def self.register_on_complete(env)
        env[:response].on_complete do |finished_env|
          finished_env[:body] = ::Nokogiri::XML(finished_env[:body])
        end 
      end 
    rescue LoadError, NameError => e
      self.load_error = e 
      raise e
    end 

    def initialize(app)
      super
      @parser = nil 
    end 
  end 
end 
