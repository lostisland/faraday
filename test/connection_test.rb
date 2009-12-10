require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class TestConnection < Faraday::TestCase
  describe "#get" do
    it "parses url/params into #path" do
      conn = FakeConnection.new
      resp = conn.get("http://abc.com/def.html")
      assert_equal '/def.html', resp.uri.path
    end

    it "parses url/params into #query" do
      conn = FakeConnection.new
      resp = conn.get("http://abc.com/def.html", 'a[b]' => '1 + 2')
      assert_equal "a%5Bb%5D=1%20+%202", resp.uri.query
    end

    it "parses url into #host" do
      conn = FakeConnection.new
      resp = conn.get("http://abc.com/def.html")
      assert_equal "abc.com", resp.uri.host
    end
  end

  describe "#params_to_query" do
    it "converts hash of params to URI-escaped query string" do
      conn = Faraday::Connection.new
      assert_equal "a%5Bb%5D=1%20+%202", conn.params_to_query('a[b]' => '1 + 2')
    end
  end
end
