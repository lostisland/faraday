require File.expand_path("../../connection_test", __FILE__)
Faraday.require_lib 'rack_builder'

class RackBuilderConnectionTest < Faraday::TestCase
  include ConnectionTests

  alias connection rack_builder_connection
end

