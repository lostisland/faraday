require File.expand_path("../../connection_test", __FILE__)
Faraday.require_lib 'rack_builder'

class RackBuilderConnectionTest < Faraday::TestCase
  include ConnectionTests

  def connection(url = nil, options = nil, &block)
    if url.is_a?(Hash)
      options = url
      url = nil
    end

    options = Faraday::ConnectionOptions.from(options)
    options.builder_class = Faraday::RackBuilder

    args = [url, options.to_hash].compact

    Faraday::Connection.new(*args, &block)
  end
end

