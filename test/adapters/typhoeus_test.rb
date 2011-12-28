require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helper'))

module Adapters
  class TyphoeusTest < Faraday::TestCase
    def setup
      @connection = Faraday.new('http://disney.com') do |b|
        b.adapter :typhoeus
      end
    end

    def test_handles_user_agent
      # default typhoeus agent
      stub_request(:get, 'disney.com/world').with(:headers => {'User-Agent'=>'Faraday Agent'}){ |request|
        request.headers["User-Agent"] == 'Faraday Agent'
      }
      @connection.get('/world', :user_agent => 'Faraday Agent')
    end

  end if defined? ::Typhoeus
end
