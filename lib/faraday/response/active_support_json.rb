module Faraday
  class Response::ActiveSupportJson < Response::Middleware
    begin
      if !defined?(ActiveSupport::JSON)
        require 'active_support'
        ActiveSupport::JSON
      end
    rescue LoadError, NameError => e
      self.load_error = e
    end

    def parse(body)
      ActiveSupport::JSON.decode(body)
    rescue Object
      raise Faraday::Error::ParsingError, $!
    end
  end
end
