module Faraday
  class Response::JSON < Response::Middleware
    adapter_name = nil

    # loads the JSON decoder either from yajl-ruby or activesupport
    dependency do
      require 'yajl'
      adapter_name = Yajl::Parser.name
    end

    dependency do
      require 'active_support/json/decoding'
      adapter_name = ActiveSupport::JSON.name
    end unless loaded?

    # defines a parser block depending on which adapter has loaded
    case adapter_name
    when 'Yajl::Parser'
      define_parser do |body|
        Yajl::Parser.parse(body)
      end
    when 'ActiveSupport::JSON'
      define_parser do |body|
        unless body.nil? or body.empty?
          result = ActiveSupport::JSON.decode(body)
          raise ActiveSupport::JSON.backend::ParseError if String === result
          result
        end
      end
    end
  end
end
