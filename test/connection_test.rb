require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class TestConnection < Faraday::TestCase
  describe "#initialize" do
    it "parses @host out of given url" do
      conn = Faraday::Connection.new "http://sushi.com"
      assert_equal 'sushi.com', conn.host
    end

    it "parses nil @port out of given url" do
      conn = Faraday::Connection.new "http://sushi.com"
      assert_nil conn.port
    end

    it "parses @scheme out of given url" do
      conn = Faraday::Connection.new "http://sushi.com"
      assert_equal 'http', conn.scheme
    end

    it "parses @port out of given url" do
      conn = Faraday::Connection.new "http://sushi.com:815"
      assert_equal 815, conn.port
    end

    it "parses nil @path_prefix out of given url" do
      conn = Faraday::Connection.new "http://sushi.com"
      assert_equal '/', conn.path_prefix
    end

    it "parses @path_prefix out of given url" do
      conn = Faraday::Connection.new "http://sushi.com/fish"
      assert_equal '/fish', conn.path_prefix
    end

    it "parses @path_prefix out of given url option" do
      conn = Faraday::Connection.new :url => "http://sushi.com/fish"
      assert_equal '/fish', conn.path_prefix
    end

    it "stores default params from options" do
      conn = Faraday::Connection.new :params => {:a => 1}
      assert_equal 1, conn.params['a']
    end

    it "stores default params from uri" do
      conn = Faraday::Connection.new "http://sushi.com/fish?a=1", :params => {'b' => '2'}
      assert_equal '1', conn.params['a']
      assert_equal '2', conn.params['b']
    end

    it "stores default headers from options" do
      conn = Faraday::Connection.new :headers => {:a => 1}
      assert_equal '1', conn.headers['A']
    end
  end

  describe "#build_url" do
    it "uses Connection#host as default URI host" do
      conn = Faraday::Connection.new
      conn.host = 'sushi.com'
      uri = conn.build_url("/sake.html")
      assert_equal 'sushi.com', uri.host
    end

    it "uses Connection#port as default URI port" do
      conn = Faraday::Connection.new
      conn.port = 23
      uri = conn.build_url("http://sushi.com")
      assert_equal 23, uri.port
    end

    it "uses Connection#scheme as default URI scheme" do
      conn = Faraday::Connection.new 'http://sushi.com'
      uri = conn.build_url("/sake.html")
      assert_equal 'http', uri.scheme
    end

    it "uses Connection#path_prefix to customize the path" do
      conn = Faraday::Connection.new
      conn.path_prefix = '/fish'
      uri = conn.build_url("sake.html")
      assert_equal '/fish/sake.html', uri.path
    end

    it "uses '/' Connection#path_prefix to customize the path" do
      conn = Faraday::Connection.new
      conn.path_prefix = '/'
      uri = conn.build_url("sake.html")
      assert_equal '/sake.html', uri.path
    end

    it "forces Connection#path_prefix to be absolute" do
      conn = Faraday::Connection.new
      conn.path_prefix = 'fish'
      uri = conn.build_url("sake.html")
      assert_equal '/fish/sake.html', uri.path
    end

    it "ignores Connection#path_prefix trailing slash" do
      conn = Faraday::Connection.new
      conn.path_prefix = '/fish/'
      uri = conn.build_url("sake.html")
      assert_equal '/fish/sake.html', uri.path
    end

    it "allows absolute URI to ignore Connection#path_prefix" do
      conn = Faraday::Connection.new
      conn.path_prefix = '/fish'
      uri = conn.build_url("/sake.html")
      assert_equal '/sake.html', uri.path
    end

    it "parses url/params into #path" do
      conn = Faraday::Connection.new
      uri = conn.build_url("http://sushi.com/sake.html")
      assert_equal '/sake.html', uri.path
    end

    it "parses url/params into #query" do
      conn = Faraday::Connection.new
      uri = conn.build_url("http://sushi.com/sake.html", 'a[b]' => '1 + 2')
      assert_equal "a%5Bb%5D=1%20%2B%202", uri.query
    end

    it "mashes default params and given params together" do
      conn = Faraday::Connection.new 'http://sushi.com/api?token=abc', :params => {'format' => 'json'}
      url = conn.build_url("nigiri?page=1", :limit => 5)
      assert_match /limit=5/,      url.query
      assert_match /page=1/,       url.query
      assert_match /format=json/,  url.query
      assert_match /token=abc/,    url.query
    end

    it "overrides default params with given params" do
      conn = Faraday::Connection.new 'http://sushi.com/api?token=abc', :params => {'format' => 'json'}
      url = conn.build_url("nigiri?page=1", :limit => 5, :token => 'def', :format => 'xml')
      assert_match /limit=5/,        url.query
      assert_match /page=1/,         url.query
      assert_match /format=xml/,     url.query
      assert_match /token=def/,      url.query
      assert_no_match /format=json/, url.query
      assert_no_match /token=abc/,   url.query
    end

    it "parses url into #host" do
      conn = Faraday::Connection.new
      uri = conn.build_url("http://sushi.com/sake.html")
      assert_equal "sushi.com", uri.host
    end

    it "parses url into #port" do
      conn = Faraday::Connection.new
      uri = conn.build_url("http://sushi.com/sake.html")
      assert_nil uri.port
    end
  end

  describe "#params_to_query" do
    it "converts hash of params to URI-escaped query string" do
      conn = Faraday::Connection.new
      class << conn
        public :build_query
      end
      assert_equal "a%5Bb%5D=1%20%2B%202", conn.build_query('a[b]' => '1 + 2')
    end
  end
end
