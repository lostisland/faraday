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
      @connection.get('/world', nil, :user_agent => 'Faraday Agent')
    end

    def test_typhoeus_adapter_can_post_with_hash
      stub_request(:post, "http://disney.com/world").
          with(:body => "q=1&x=2").
          to_return(:status => 200, :body => "", :headers => {})

      conn = Faraday.new(:url => 'http://disney.com') do |b|
        b.adapter :typhoeus
      end

      hash = { :q => 1, :x => 2 }
      conn.post('/world', hash)
    end

    def test_default_adapter_can_post_with_hash
      stub_request(:post, "http://disney.com/world").
          with(:body => {"q"=>"1", "x"=>"2"},
               :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})

      conn = Faraday.new(:url => 'http://disney.com')

      hash = { :q => 1, :x => 2 }
      conn.post('/world', hash)
    end

  end if defined? ::Typhoeus
end
