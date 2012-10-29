require File.expand_path("../../../integration_helper", __FILE__)
Faraday.require_lib 'rack_builder/adapter/patron'

module RackBuilderAdapters
  class Patron < Faraday::RackBuilderTestCase

    def adapter() :patron end

    Faraday::Integration.apply(self, :NonParallel) do
      # https://github.com/toland/patron/issues/34
      undef :test_PATCH_send_url_encoded_params

      # https://github.com/toland/patron/issues/52
      undef :test_GET_with_body
    end unless jruby?

  end
end

