module Adapters
  class LoggerTest < Faraday::TestCase
    def test_logs_method_and_url
      @conn.get '/hello', nil, :accept => 'text/html'
      assert_match 'request: GET http:/hello', @io.string
    end

    def test_logs_status_code
      @conn.get '/hello', nil, :accept => 'text/html'
      assert_match 'response: Status 200', @io.string
    end
  end
end
