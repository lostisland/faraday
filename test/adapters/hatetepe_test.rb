require File.expand_path("../integration", __FILE__)

module Adapters
  class HatetepeTest < Faraday::TestCase

    def adapter() :hatetepe end

    if RUBY_VERSION >= "1.9"
      Integration.apply(self)
    else
      warn "Warning: Skipping Hatetepe tests in 1.8 mode"
    end
  end
end
