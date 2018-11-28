require File.expand_path('../helper', __FILE__)

class FakeFaradayConnection
  def initialize(*); end
end

class FaradayTest < Faraday::TestCase
  def test_instantiate_with_injected_connection_class
    conn = Faraday.new "example.com", connection_class: FakeFaradayConnection

    assert_equal conn.class, FakeFaradayConnection
  end
end
