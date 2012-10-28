require File.expand_path("../../params_test", __FILE__)
Faraday.require_lib 'rack_builder'

class RackBuilderParamsTest < Faraday::TestCase
  include ParamTests

  def create_connection(url = nil, options = nil)
    @conn ||= begin
      if url.is_a?(Hash)
        options = url
        url = nil
      end

      options = Faraday::ConnectionOptions.from(options)
      options.builder_class = Faraday::RackBuilder

      args = [url, options.to_hash].compact

      Faraday::Connection.new(*args) do |conn|
        yield conn if block_given?
        class << conn.builder
          undef app
          def app() lambda { |env| env } end
        end
      end
    end
  end
end


