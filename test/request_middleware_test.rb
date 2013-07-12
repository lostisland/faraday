# encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

Faraday::CompositeReadIO.class_eval { attr_reader :ios }

class RequestMiddlewareTest < Faraday::TestCase
  def setup
    @conn = Faraday.new do |b|
      b.request :multipart
      b.request :url_encoded
      b.adapter :test do |stub|
        stub.post('/echo') do |env|
          posted_as = env[:request_headers]['Content-Type']
          [200, {'Content-Type' => posted_as}, env[:body]]
        end
      end
    end
  end

  def with_utf8
    if defined?(RUBY_VERSION) && RUBY_VERSION.match(/1.8.\d/)
      begin
        previous_kcode = $KCODE
        $KCODE = "UTF8"
        yield
      ensure
        $KCODE = previous_kcode
      end
    else
      yield
    end
  end

  def test_does_nothing_without_payload
    response = @conn.post('/echo')
    assert_nil response.headers['Content-Type']
    assert response.body.empty?
  end

  def test_ignores_custom_content_type
    response = @conn.post('/echo', { :some => 'data' }, 'content-type' => 'application/x-foo')
    assert_equal 'application/x-foo', response.headers['Content-Type']
    assert_equal({ :some => 'data' }, response.body)
  end

  def test_url_encoded_no_header
    response = @conn.post('/echo', { :fruit => %w[apples oranges] })
    assert_equal 'application/x-www-form-urlencoded', response.headers['Content-Type']
    assert_equal 'fruit%5B%5D=apples&fruit%5B%5D=oranges', response.body
  end

  def test_url_encoded_with_header
    response = @conn.post('/echo', {'a'=>123}, 'content-type' => 'application/x-www-form-urlencoded')
    assert_equal 'application/x-www-form-urlencoded', response.headers['Content-Type']
    assert_equal 'a=123', response.body
  end

  def test_url_encoded_nested
    response = @conn.post('/echo', { :user => {:name => 'Mislav', :web => 'mislav.net'} })
    assert_equal 'application/x-www-form-urlencoded', response.headers['Content-Type']
    expected = { 'user' => {'name' => 'Mislav', 'web' => 'mislav.net'} }
    assert_equal expected, Faraday::Utils.parse_nested_query(response.body)
  end

  def test_url_encoded_unicode
    err = capture_warnings {
      response = @conn.post('/echo', {:str => "eé cç aã aâ"})
      assert_equal "str=e%C3%A9+c%C3%A7+a%C3%A3+a%C3%A2", response.body
    }
    assert err.empty?, "stderr did include: #{err}"
  end

  def test_url_encoded_unicode_with_kcode_set
    with_utf8 do
      err = capture_warnings {
        response = @conn.post('/echo', {:str => "eé cç aã aâ"})
        assert_equal "str=e%C3%A9+c%C3%A7+a%C3%A3+a%C3%A2", response.body
      }
      assert err.empty?, "stderr did include: #{err}"
    end
  end

  def test_url_encoded_nested_keys
    response = @conn.post('/echo', {'a'=>{'b'=>{'c'=>['d']}}})
    assert_equal "a%5Bb%5D%5Bc%5D%5B%5D=d", response.body
  end

  def test_multipart
    # assume params are out of order
    regexes = [
      /name\=\"a\"/,
      /name=\"b\[c\]\"\; filename\=\"request_middleware_test\.rb\"/,
      /name=\"b\[d\]\"/]

    payload = {:a => 1, :b => {:c => Faraday::UploadIO.new(__FILE__, 'text/x-ruby'), :d => 2}}
    response = @conn.post('/echo', payload)

    assert_kind_of Faraday::CompositeReadIO, response.body
    assert_equal "multipart/form-data; boundary=%s" % Faraday::Request::Multipart::DEFAULT_BOUNDARY,
      response.headers['Content-Type']

    response.body.send(:ios).map{|io| io.read}.each do |io|
      if re = regexes.detect { |r| io =~ r }
        regexes.delete re
      end
    end
    assert_equal [], regexes
  end

  def test_multipart_with_arrays
    # assume params are out of order
    regexes = [
      /name\=\"a\"/,
      /name=\"b\[\]\[c\]\"\; filename\=\"request_middleware_test\.rb\"/,
      /name=\"b\[\]\[d\]\"/]

    payload = {:a => 1, :b =>[{:c => Faraday::UploadIO.new(__FILE__, 'text/x-ruby'), :d => 2}]}
    response = @conn.post('/echo', payload)

    assert_kind_of Faraday::CompositeReadIO, response.body
    assert_equal "multipart/form-data; boundary=%s" % Faraday::Request::Multipart::DEFAULT_BOUNDARY,
      response.headers['Content-Type']

    response.body.send(:ios).map{|io| io.read}.each do |io|
      if re = regexes.detect { |r| io =~ r }
        regexes.delete re
      end
    end
    assert_equal [], regexes
  end

end
