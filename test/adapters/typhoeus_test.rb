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
      stub_request(:get, 'disney.com/hello').with(:headers => {'User-Agent'=>'Typhoeus - http://github.com/dbalatero/typhoeus/tree/master'}){ |request|
        request.headers["User-Agent"] == 'Typhoeus - http://github.com/dbalatero/typhoeus/tree/master'
      }
      @connection.get('/hello')
      stub_request(:get, 'disney.com/world').with(:headers => {'User-Agent'=>'Faraday Agent'}){ |request|
        request.headers["User-Agent"] == 'Faraday Agent'
      }
      @connection.get('/world', :user_agent => 'Faraday Agent')
    end

  end
end
