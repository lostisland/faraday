require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class RequestMiddlewareTest < Faraday::TestCase
  def setup
    @conn = Faraday.new do |b|
      b.request :json
      b.adapter :test do |stub|
        stub.post('/echo') do |env|
          posted_as = env[:request_headers]['Content-Type']
          [200, {'Content-Type' => posted_as}, env[:body]]
        end
      end
    end
  end
  
  def test_does_nothing_without_payload
    response = @conn.post('/echo')
    assert_nil response.headers['Content-Type']
    assert response.body.empty?
  end
  
  def test_encodes_hash
    response = @conn.post('/echo', { :fruit => %w[apples oranges] })
    assert_equal 'application/json', response.headers['Content-Type']
    assert_equal '{"fruit":["apples","oranges"]}', response.body
  end
  
  def test_skips_encoding_for_strings
    response = @conn.post('/echo', '{"a":"b"}')
    assert_equal 'application/json', response.headers['Content-Type']
    assert_equal '{"a":"b"}', response.body
  end
end
