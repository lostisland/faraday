require File.expand_path("../../params_test", __FILE__)
Faraday.require_lib 'rack_builder'

class RackBuilderParamsTest < Faraday::TestCase
  include ParamTests

  def create_connection(url = nil, options = nil)
    @conn ||= begin
      rack_builder_connection(url, options) do |conn|
        yield conn if block_given?
        class << conn.builder
          undef app
          def app() lambda { |env| env } end
        end
      end
    end
  end
end


