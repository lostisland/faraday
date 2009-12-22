module Faraday
  class TestConnection < Connection
    include Faraday::Adapter::MockRequest
  end
end
