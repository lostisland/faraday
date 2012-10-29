require File.expand_path("../helper", __FILE__)

module Faraday
  require_libs 'integration'

  class RackBuilderTestCase < TestCase
    def create_connection(options = {})
      if adapter == :default
        builder_block = nil
      else
        builder_block = Proc.new do |b|
          b.request :multipart
          b.request :url_encoded
          b.adapter adapter, *adapter_options
        end
      end

      server = self.class.live_server
      url = '%s://%s:%d' % [server.scheme, server.host, server.port]

      options[:ssl] ||= {}
      options[:ssl][:ca_file] ||= ENV['SSL_FILE']

      rack_builder_connection(url, options, &builder_block).tap do |conn|
        conn.headers['X-Faraday-Adapter'] = adapter.to_s
        adapter_handler = conn.builder.handlers.last
        Faraday.require_lib 'rack_builder/response/raise_error'
        conn.builder.insert_before adapter_handler, Faraday::RackBuilder::Response::RaiseError
      end
    end
  end
end

