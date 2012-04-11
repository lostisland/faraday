require File.expand_path('../integration', __FILE__)

module Adapters
  class TyphoeusTest < Faraday::TestCase
    include Integration
    include Integration::Parallel
    include Integration::GetWithBody
    include Integration::PutResponseHeaders
    include Integration::Timeout

    def adapter; :typhoeus end

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
      @connection.get('/world', nil, :user_agent => 'Faraday Agent')
    end
  end
end
