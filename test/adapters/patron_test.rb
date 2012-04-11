require File.expand_path('../integration', __FILE__)

module Adapters
  class Patron < Faraday::TestCase
    include Integration
    include Integration::NonParallel

    def adapter; :patron end

    # https://github.com/toland/patron/issues/34
    undef :test_PATCH_send_url_encoded_params

    # https://github.com/toland/patron/issues/9
    undef :test_PUT_retrieves_the_response_headers
    undef :test_PUT_send_url_encoded_params
    undef :test_PUT_send_url_encoded_nested_params

    # https://github.com/toland/patron/issues/52
    undef :test_GET_with_body
  end
end
