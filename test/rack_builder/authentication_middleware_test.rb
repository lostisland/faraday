require File.expand_path("../../authentication_middleware_test", __FILE__)
Faraday.require_lib 'rack_builder'

class RackBuilderAuthenticationMiddlewareTest < Faraday::TestCase
  include AuthenticationMiddlewareTests

  alias build_connection rack_builder_connection
end

