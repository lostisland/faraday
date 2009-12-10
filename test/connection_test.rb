require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class ConnectionTest < Faraday::TestCase
  describe "#initialize" do
    it "parses @host out of given url" do
      conn = Faraday::Connection.new "http://sushi.com"
      assert_equal 'sushi.com', conn.host
    end

    it "parses nil @port out of given url" do
      conn = Faraday::Connection.new "http://sushi.com"
      assert_nil conn.port
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
  end

  describe "#build_uri" do
    it "uses Connection#host as default URI host" do
      conn = Faraday::Connection.new
      conn.host = 'sushi.com'
      uri = conn.build_uri("/sake.html")
      assert_equal 'sushi.com', uri.host
    end

    it "uses Connection#port as default URI port" do
      conn = Faraday::Connection.new
      conn.port = 23
      uri = conn.build_uri("http://sushi.com")
      assert_equal 23, uri.port
    end

    it "uses Connection#path_prefix to customize the path" do
      conn = Faraday::Connection.new
      conn.path_prefix = '/fish'
      uri = conn.build_uri("sake.html")
      assert_equal '/fish/sake.html', uri.path
    end

    it "uses '/' Connection#path_prefix to customize the path" do
      conn = Faraday::Connection.new
      conn.path_prefix = '/'
      uri = conn.build_uri("sake.html")
      assert_equal '/sake.html', uri.path
    end

    it "forces Connection#path_prefix to be absolute" do
      conn = Faraday::Connection.new
      conn.path_prefix = 'fish'
      uri = conn.build_uri("sake.html")
      assert_equal '/fish/sake.html', uri.path
    end

    it "ignores Connection#path_prefix trailing slash" do
      conn = Faraday::Connection.new
      conn.path_prefix = '/fish/'
      uri = conn.build_uri("sake.html")
      assert_equal '/fish/sake.html', uri.path
    end

    it "allows absolute URI to ignore Connection#path_prefix" do
      conn = Faraday::Connection.new
      conn.path_prefix = '/fish'
      uri = conn.build_uri("/sake.html")
      assert_equal '/sake.html', uri.path
    end

    it "parses url/params into #path" do
      conn = Faraday::Connection.new
      uri = conn.build_uri("http://sushi.com/sake.html")
      assert_equal '/sake.html', uri.path
    end

    it "parses url/params into #query" do
      conn = Faraday::Connection.new
      uri = conn.build_uri("http://sushi.com/sake.html", 'a[b]' => '1 + 2')
      assert_equal "a%5Bb%5D=1%20+%202", uri.query
    end

    it "parses url into #host" do
      conn = Faraday::Connection.new
      uri = conn.build_uri("http://sushi.com/sake.html")
      assert_equal "sushi.com", uri.host
    end

    it "parses url into #port" do
      conn = Faraday::Connection.new
      uri = conn.build_uri("http://sushi.com/sake.html")
      assert_nil uri.port
    end
  end

  describe "#params_to_query" do
    it "converts hash of params to URI-escaped query string" do
      conn = Faraday::Connection.new
      assert_equal "a%5Bb%5D=1%20+%202", conn.params_to_query('a[b]' => '1 + 2')
    end
  end
end