require File.expand_path("../../helper", __FILE__)

if !Faraday::TestCase::LIVE_SERVER
  warn "warning: test server not specified; skipping live server tests"
else
  module Adapters
    class LiveTest < Faraday::TestCase
      adapters = if ENV['ADAPTER']
        ENV['ADAPTER'].split(':').map { |name| Faraday::Adapter.lookup_module name.to_sym }
      else
        loaded_adapters  = Faraday::Adapter.all_loaded_constants
        loaded_adapters -= [Faraday::Adapter::ActionDispatch]
        loaded_adapters << :default
      end

      adapters.each do |adapter|
        define_method "test_#{adapter}_GET_retrieves_the_response_body" do
          assert_equal 'hello world', create_connection(adapter).get('hello_world').body
        end

        define_method "test_#{adapter}_GET_send_url_encoded_params" do
          resp = create_connection(adapter).get do |req|
            req.url 'hello', 'name' => 'zack'
          end
          assert_equal('hello zack', resp.body)
        end

        define_method "test_#{adapter}_GET_retrieves_the_response_headers" do
          response = create_connection(adapter).get('hello_world')
          assert_match /text\/html/, response.headers['Content-Type'], 'original case fail'
          assert_match /text\/html/, response.headers['content-type'], 'lowercase fail'
        end

        # https://github.com/geemus/excon/issues/10
        unless %[Faraday::Adapter::Excon] == adapter.to_s
          define_method "test_#{adapter}_GET_handles_headers_with_multiple_values" do
            response = create_connection(adapter).get('multi')
            assert_equal 'one, two', response.headers['set-cookie']
          end
        end

        #GET request with body
        unless %[Faraday::Adapter::NetHttp] == adapter.to_s
          define_method "test_#{adapter}_GET_with_body" do
            body = '{hello: world}'
            response = create_connection(adapter).get('get/body') do |req|
              req.body = body
            end
            assert_equal body, response.body
          end
        end

        define_method "test_#{adapter}_POST_send_url_encoded_params" do
          resp = create_connection(adapter).post do |req|
            req.url 'echo_name'
            req.body = {'name' => 'zack'}
          end
          assert_equal %("zack"), resp.body
        end

        define_method "test_#{adapter}_POST_send_url_encoded_nested_params" do
          resp = create_connection(adapter).post do |req|
            req.url 'echo_name'
            req.body = {'name' => {'first' => 'zack'}}
          end
          assert_equal %({"first"=>"zack"}), resp.body
        end

        define_method "test_#{adapter}_POST_retrieves_the_response_headers" do
          assert_match /text\/html/, create_connection(adapter).post('echo_name').headers['content-type']
        end

        define_method "test_#{adapter}_POST_sends_files" do
          resp = create_connection(adapter).post do |req|
            req.url 'file'
            req.body = {'uploaded_file' => Faraday::UploadIO.new(__FILE__, 'text/x-ruby')}
          end
          assert_equal "file live_test.rb text/x-ruby", resp.body
        end unless :default == adapter # isn't configured for multipart

        # https://github.com/toland/patron/issues/9
        if ENV['FORCE'] || %[Faraday::Adapter::Patron] != adapter.to_s
          define_method "test_#{adapter}_PUT_send_url_encoded_params" do
            resp = create_connection(adapter).put do |req|
              req.url 'echo_name'
              req.body = {'name' => 'zack'}
            end
            assert_equal %("zack"), resp.body
          end

          define_method "test_#{adapter}_PUT_send_url_encoded_nested_params" do
            resp = create_connection(adapter).put do |req|
              req.url 'echo_name'
              req.body = {'name' => {'first' => 'zack'}}
            end
            assert_equal %({"first"=>"zack"}), resp.body
          end
        end

        # https://github.com/toland/patron/issues/9
        # https://github.com/dbalatero/typhoeus/issues/84
        if ENV['FORCE'] || !%w[Faraday::Adapter::Patron Faraday::Adapter::Typhoeus].include?(adapter.to_s)
          define_method "test_#{adapter}_PUT_retrieves_the_response_headers" do
            assert_match /text\/html/, create_connection(adapter).put('echo_name').headers['content-type']
          end
        end

        # https://github.com/toland/patron/issues/34
        unless %w[Faraday::Adapter::Patron Faraday::Adapter::EMSynchrony].include? adapter.to_s
          define_method "test_#{adapter}_PATCH_send_url_encoded_params" do
            resp = create_connection(adapter).patch('echo_name', 'name' => 'zack')
            assert_equal %("zack"), resp.body
          end
        end

        unless %[Faraday::Adapter::EMSynchrony] == adapter.to_s
          define_method "test_#{adapter}_OPTIONS" do
            resp = create_connection(adapter).run_request(:options, '/options', nil, {})
            assert_equal "hi", resp.body
          end
        end

        define_method "test_#{adapter}_HEAD_send_url_encoded_params" do
          resp = create_connection(adapter).head do |req|
            req.url 'hello', 'name' => 'zack'
          end
          assert_match /text\/html/, resp.headers['content-type']
        end

        define_method "test_#{adapter}_HEAD_retrieves_no_response_body" do
          assert_equal '', create_connection(adapter).head('hello_world').body.to_s
        end

        define_method "test_#{adapter}_HEAD_retrieves_the_response_headers" do
          assert_match /text\/html/, create_connection(adapter).head('hello_world').headers['content-type']
        end

        define_method "test_#{adapter}_DELETE_retrieves_the_response_headers" do
          assert_match /text\/html/, create_connection(adapter).delete('delete_with_json').headers['content-type']
        end

        define_method "test_#{adapter}_DELETE_retrieves_the_body" do
          assert_match /deleted/, create_connection(adapter).delete('delete_with_json').body
        end

        define_method "test_#{adapter}_async_requests_clear_parallel_manager_after_running_a_single_request" do
          connection = create_connection(adapter)
          assert !connection.in_parallel?
          resp = connection.get('hello_world')
          assert !connection.in_parallel?
          assert_equal 'hello world', connection.get('hello_world').body
        end

        define_method "test_#{adapter}_async_requests_uses_parallel_manager_to_run_multiple_json_requests" do
          resp1, resp2 = nil, nil

          connection = create_connection(adapter)
          adapter    = real_adapter_for(adapter)

          connection.in_parallel(adapter.setup_parallel_manager) do
            resp1 = connection.get('json')
            resp2 = connection.get('json')
            if adapter.supports_parallel_requests?
              assert connection.in_parallel?
              assert_nil resp1.body
              assert_nil resp2.body
            end
          end
          assert !connection.in_parallel?
          assert_equal '[1,2,3]', resp1.body
          assert_equal '[1,2,3]', resp2.body
        end

        if adapter.to_s == "Faraday::Adapter::EMSynchrony"
          instance_methods.grep(%r{Faraday::Adapter::EMSynchrony}).each do |method|
            em = method.to_s.sub %r{^test_}, "test_under_em_"
            define_method em do
              EM.run do
                Fiber.new do
                  self.send method
                  EM.stop
                end.resume
              end
            end
          end
        end

        if %w[Faraday::Adapter::Patron Faraday::Adapter::NetHttp].include?(adapter.to_s)
          define_method "test_#{adapter}_timeout" do
            conn = create_connection(adapter, :request => {:timeout => 1, :read_timeout => 1})
            assert_raise Faraday::Error::TimeoutError do
              conn.get '/slow'
            end
          end
        end
      end

      def create_connection(adapter, options = {})
        if adapter == :default
          builder_block = nil
        else
          builder_block = Proc.new do |b|
            b.request :multipart
            b.request :url_encoded
            b.use adapter
          end
        end

        Faraday::Connection.new(LIVE_SERVER, options, &builder_block).tap do |conn|
          conn.headers['X-Faraday-Adapter'] = adapter.to_s
          adapter_handler = conn.builder.handlers.last
          conn.builder.insert_before adapter_handler, Faraday::Response::RaiseError
        end
      end

      def real_adapter_for(adapter)
        if adapter == :default
          Faraday::Adapter.lookup_module(Faraday.default_adapter)
        else
          adapter
        end
      end
    end
  end
end
