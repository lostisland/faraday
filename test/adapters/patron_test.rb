require File.expand_path('../integration', __FILE__)

module Adapters
  class Patron < Faraday::TestCase
    include Integration
    include Integration::NonParallel
    include Integration::GetWithBody
    include Integration::PutResponseHeaders
    include Integration::Timeout

    def adapter; :patron end

    # https://github.com/toland/patron/issues/9
    def test_PUT_send_url_encoded_params
      resp = create_connection(adapter).put do |req|
        req.url 'echo_name'
        req.body = {'name' => 'zack'}
      end
      assert_equal %("zack"), resp.body
    end

    def test_PUT_send_url_encoded_nested_params
      resp = create_connection(adapter).put do |req|
        req.url 'echo_name'
        req.body = {'name' => {'first' => 'zack'}}
      end
      assert_equal %({"first"=>"zack"}), resp.body
    end

    # https://github.com/toland/patron/issues/34
    def test_PATCH_send_url_encoded_params
      resp = create_connection(adapter).patch('echo_name', 'name' => 'zack')
      assert_equal %("zack"), resp.body
    end
  end
end
