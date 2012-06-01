require File.expand_path('../integration', __FILE__)

module Adapters
  class Patron < Faraday::TestCase

    def adapter() :patron end

    Integration.apply(self, :NonParallel, :NonStreaming) do
      # https://github.com/toland/patron/issues/34
      undef :test_PATCH_send_url_encoded_params

      # https://github.com/toland/patron/issues/52
      undef :test_GET_with_body
    end

  end unless defined? RUBY_ENGINE and 'jruby' == RUBY_ENGINE
end
