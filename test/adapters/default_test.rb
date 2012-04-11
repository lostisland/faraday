require File.expand_path('../integration', __FILE__)

module Adapters
  class DefaultTest < Faraday::TestCase
    include Integration
    include Integration::NonParallel

    def adapter; :default end

    undef :test_POST_sends_files
  end
end
