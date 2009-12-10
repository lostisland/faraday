require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class TestConnection < Faraday::TestCase
  describe "#build_uri" do
    it "uses Connection#host as default URI host" do
      conn = FakeConnection.new
      conn.host = 'sushi.com'
      uri = conn.build_uri("/sake.html")
      assert_equal 'sushi.com', uri.host
    end

    it "uses Connection#port as default URI port" do
      conn = FakeConnection.new
      conn.port = 23
      uri = conn.build_uri("http://sushi.com")
      assert_equal 23, uri.port
    end

    it "uses Connection#path_prefix to customize the path" do
      conn = FakeConnection.new
      conn.path_prefix = '/fish'
      uri = conn.build_uri("sake.html")
      assert_equal '/fish/sake.html', uri.path
    end

    it "forces Connection#path_prefix to be absolute" do
      conn = FakeConnection.new
      conn.path_prefix = 'fish'
      uri = conn.build_uri("sake.html")
      assert_equal '/fish/sake.html', uri.path
    end

    it "ignores Connection#path_prefix trailing slash" do
      conn = FakeConnection.new
      conn.path_prefix = '/fish/'
      uri = conn.build_uri("sake.html")
      assert_equal '/fish/sake.html', uri.path
    end

    it "allows absolute URI to ignore Connection#path_prefix" do
      conn = FakeConnection.new
      conn.path_prefix = '/fish'
      uri = conn.build_uri("/sake.html")
      assert_equal '/sake.html', uri.path
    end

    it "parses url/params into #path" do
      conn = FakeConnection.new
      uri = conn.build_uri("http://sushi.com/sake.html")
      assert_equal '/sake.html', uri.path
    end

    it "parses url/params into #query" do
      conn = FakeConnection.new
      uri = conn.build_uri("http://sushi.com/sake.html", 'a[b]' => '1 + 2')
      assert_equal "a%5Bb%5D=1%20+%202", uri.query
    end

    it "parses url into #host" do
      conn = FakeConnection.new
      uri = conn.build_uri("http://sushi.com/sake.html")
      assert_equal "sushi.com", uri.host
    end

    it "parses url into #port" do
      conn = FakeConnection.new
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
