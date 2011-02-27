module Faraday
  class Response::Yajl < Response::Middleware
    begin
      require 'yajl'
    rescue LoadError, NameError => e
      self.load_error = e
    end

    def parse(body)
      Yajl::Parser.parse(body)
    rescue Object
      raise Faraday::Error::ParsingError, $!
    end
  end
end
