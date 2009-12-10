require 'rubygems'
require 'context'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'faraday'

module Faraday
  class TestCase < Test::Unit::TestCase
    LIVE_SERVER = 'http://localhost:4567'

    class TestConnection < Faraday::Connection
      def _get(uri, headers)
        TestResponse.new(uri, nil, headers)
      end
    end

    class TestResponse < Struct.new(:uri, :content, :headers)
    end
  end
end
