require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helper'))

module Adapters
  class EMSynchronyTest < Faraday::TestCase
    def setup
      @connection = Faraday.new('http://disney.com') do |b|
        b.adapter :em_synchrony
      end
    end

    def test_connection
      stub_request(:any, 'http://disney.com')
      resp = @connection.get "/"
      assert_equal 200, resp.status
    end
  end
end
