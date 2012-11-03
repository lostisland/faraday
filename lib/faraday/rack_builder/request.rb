module Faraday::RackBuilder::Request
  extend Faraday::MiddlewareRegistry

  register_middleware File.expand_path('../request', __FILE__),
    :url_encoded => [:UrlEncoded, 'url_encoded'],
    :multipart => [:Multipart, 'multipart'],
    :retry => [:Retry, 'retry'],
    :authorization => [:Authorization, 'authorization'],
    :basic_auth => [:BasicAuthentication, 'basic_authentication'],
    :token_auth => [:TokenAuthentication, 'token_authentication']
end
