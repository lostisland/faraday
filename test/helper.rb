require 'rubygems'
require 'context'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'faraday'

module Faraday
  class TestCase < Test::Unit::TestCase
    class FakeConnection < Faraday::Connection
      def _get(uri, headers)
        FakeResponse.new(uri, nil, headers)
      end
    end

    class FakeResponse < Struct.new(:uri, :content, :headers)
    end
  end
end
