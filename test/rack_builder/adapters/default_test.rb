require File.expand_path('../../../integration_helper', __FILE__)

module RackBuilderAdapters
  class DefaultTest < Faraday::RackBuilderTestCase

    def adapter() :default end

    Faraday::Integration.apply(self, :NonParallel) do
      # default stack is not configured with Multipart
      undef :test_POST_sends_files
    end
  end
end

