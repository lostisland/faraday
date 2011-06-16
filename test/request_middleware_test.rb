require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require 'rack/utils'

Faraday::CompositeReadIO.send :attr_reader, :ios

class RequestMiddlewareTest < Faraday::TestCase
  def setup
    @conn = Faraday.new do |b|
      b.request :multipart
      b.request :url_encoded
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

  def test_ignores_custom_content_type
    response = @conn.post('/echo', { :some => 'data' }, 'content-type' => 'application/x-foo')
    assert_equal 'application/x-foo', response.headers['Content-Type']
    assert_equal({ :some => 'data' }, response.body)
  end

  def test_json_encodes_hash
    response = @conn.post('/echo', { :fruit => %w[apples oranges] }, 'content-type' => 'application/json')
    assert_equal 'application/json', response.headers['Content-Type']
    assert_equal '{"fruit":["apples","oranges"]}', response.body
  end

  def test_json_skips_encoding_for_strings
    response = @conn.post('/echo', '{"a":"b"}', 'content-type' => 'application/json')
    assert_equal 'application/json', response.headers['Content-Type']
    assert_equal '{"a":"b"}', response.body
  end

  def test_url_encoded_no_header
    response = @conn.post('/echo', { :fruit => %w[apples oranges] })
    assert_equal 'application/x-www-form-urlencoded', response.headers['Content-Type']
    assert_equal 'fruit[]=apples&fruit[]=oranges', response.body
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
    assert_equal expected, Rack::Utils.parse_nested_query(response.body)
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
    assert_equal "multipart/form-data;boundary=%s" % Faraday::Request::Multipart::DEFAULT_BOUNDARY,
      response.headers['Content-Type']

    response.body.send(:ios).map{|io| io.read}.each do |io|
      if re = regexes.detect { |r| io =~ r }
        regexes.delete re
      end
    end
    assert_equal [], regexes
  end
end

class AuthHMACMiddlewareTest < Faraday::TestCase
  def setup
    Faraday::Request::AuthHMAC.keys.clear
    @access_id, @secret = "id", "secret"
    @connection = Faraday.new :url => 'http://sushi.com/api'
    @request    = Faraday::Request.create(:get) do |req|
      req.url 'foo.json'
      req.body = "test"
    end
    generate_env!
  end

  def test_auth_hmac_skips_when_sign_is_not_called
    call(@env)
    assert_nil @env[:request_headers]['Authorization']
  end

  def test_request_will_instruct_middleware_to_sign_if_told_to
    assert_nil @env[:sign_with]

    @request.sign! @access_id, @secret
    generate_env!
    assert_equal @access_id, @env[:sign_with]
  end

  def test_request_instructed_to_sign_a_request_will_result_in_a_correctly_signed_request
    @env[:sign_with] = @access_id
    klass.keys = {@access_id => @secret}

    call(@env)
    assert_not_nil @env[:request_headers]['Authorization']
    assert signed?(@env, @access_id, @secret), "should be signed"
  end

  protected

  def klass
    Faraday::Request::AuthHMAC
  end

  def call(env)
    klass.new(lambda{|_|}).call(env)
  end

  def generate_env!
    @env = @request.to_env(@connection)
  end

  # Based on the `authenticated?` method in auth-hmac.
  # https://github.com/dnclabs/auth-hmac/blob/master/lib/auth-hmac.rb#L252
  def signed?(env, access_id, secret)
    auth  = klass.auth
    rx = Regexp.new("#{klass.options[:service_id]} ([^:]+):(.+)$")
    if md = rx.match(env[:request_headers][klass::AUTH_HEADER])
      access_key_id = md[1]
      hmac = md[2]
      !secret.nil? && hmac == auth.signature(env, secret)
    else
      false
    end
  end

end
