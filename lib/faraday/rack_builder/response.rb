module Faraday::RackBuilder::Response
  extend Faraday::MiddlewareRegistry

  register_middleware File.expand_path('../response', __FILE__),
    :raise_error => [:RaiseError, 'raise_error'],
    :logger => [:Logger, 'logger']
end

