require File.expand_path('../helper', __FILE__)

class HeadersTest < Faraday::TestCase
  def setup
    @headers = Faraday::Utils::Headers.new
  end

  def test_normalizes_different_capitalizations
    @headers['Content-Type'] = 'application/json'
    assert_equal ['Content-Type'], @headers.keys
    assert_equal 'application/json', @headers['Content-Type']
    assert_equal 'application/json', @headers['CONTENT-TYPE']
    assert_equal 'application/json', @headers['content-type']
    assert @headers.include?('content-type')

    @headers['content-type'] = 'application/xml'
    assert_equal ['Content-Type'], @headers.keys
    assert_equal 'application/xml', @headers['Content-Type']
    assert_equal 'application/xml', @headers['CONTENT-TYPE']
    assert_equal 'application/xml', @headers['content-type']
  end

  def test_delete_key
    @headers['Content-Type'] = 'application/json'
    assert_equal 1, @headers.size
    assert @headers.include?('content-type')
    assert_equal 'application/json', @headers.delete('content-type')
    assert_equal 0, @headers.size
    assert !@headers.include?('content-type')
    assert_equal nil, @headers.delete('content-type')
  end

  def test_parse_response_headers_leaves_http_status_line_out
    @headers.parse("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
    assert_equal %w(Content-Type), @headers.keys
  end

  def test_parse_response_headers_parses_lower_cased_header_name_and_value
    @headers.parse("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
    assert_equal 'text/html', @headers['content-type']
  end

  def test_parse_response_headers_parses_lower_cased_header_name_and_value_with_colon
    @headers.parse("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nLocation: http://sushi.com/\r\n\r\n")
    assert_equal 'http://sushi.com/', @headers['location']
  end

  def test_parse_response_headers_parses_blank_lines
    @headers.parse("HTTP/1.1 200 OK\r\n\r\nContent-Type: text/html\r\n\r\n")
    assert_equal 'text/html', @headers['content-type']
  end
end

