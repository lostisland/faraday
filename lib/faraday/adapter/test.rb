module Faraday
  class Adapter
    # test = Faraday::Connection.new do
    #   use Faraday::Adapter::Test do |stub|
    #     stub.get '/nigiri/sake.json' do
    #       [200, {}, 'hi world']
    #     end
    #   end
    # end
    #
    # resp = test.get '/nigiri/sake.json'
    # resp.body # => 'hi world'
    #
    class Test < Faraday::Adapter
      attr_accessor :stubs

      class Stubs
        class NotFound < StandardError
        end

        def initialize
          # {:get => [Stub, Stub]}
          @stack, @consumed = {}, {}
          yield(self) if block_given?
        end

        def empty?
          @stack.empty?
        end

        def match(request_method, path, headers, body)
          return false if !@stack.key?(request_method)
          stack = @stack[request_method]
          consumed = (@consumed[request_method] ||= [])

          if stub = matches?(stack, path, headers, body)
            consumed << stack.delete(stub)
            stub
          else
            matches?(consumed, path, headers, body)
          end
        end

        def get(path, headers = {}, &block)
          new_stub(:get, path, headers, &block)
        end

        def head(path, headers = {}, &block)
          new_stub(:head, path, headers, &block)
        end

        def post(path, body=nil, headers = {}, &block)
          new_stub(:post, path, headers, body, &block)
        end

        def put(path, body=nil, headers = {}, &block)
          new_stub(:put, path, headers, body, &block)
        end

        def patch(path, body=nil, headers = {}, &block)
          new_stub(:patch, path, headers, body, &block)
        end

        def delete(path, headers = {}, &block)
          new_stub(:delete, path, headers, &block)
        end

        def options(path, headers = {}, &block)
          new_stub(:options, path, headers, &block)
        end

        # Raises an error if any of the stubbed calls have not been made.
        def verify_stubbed_calls
          failed_stubs = []
          @stack.each do |method, stubs|
            unless stubs.size == 0
              failed_stubs.concat(stubs.map {|stub|
                "Expected #{method} #{stub}."
              })
            end
          end
          raise failed_stubs.join(" ") unless failed_stubs.size == 0
        end

        protected

        def new_stub(request_method, path, headers = {}, body=nil, &block)
          normalized_path = Faraday::Utils.normalize_path(path)
          (@stack[request_method] ||= []) << Stub.new(normalized_path, headers, body, block)
        end

        def matches?(stack, path, headers, body)
          stack.detect { |stub| stub.matches?(path, headers, body) }
        end
      end

      class Stub < Struct.new(:path, :params, :headers, :body, :block)
        def initialize(full, headers, body, block)
          path, query = full.split('?')
          params = query ?
            Faraday::Utils.parse_nested_query(query) :
            {}
          super(path, params, headers, body, block)
        end

        def matches?(request_uri, request_headers, request_body)
          request_path, request_query = request_uri.split('?')
          request_params = request_query ?
            Faraday::Utils.parse_nested_query(request_query) :
            {}
          request_path == path &&
            params_match?(request_params) &&
            (body.to_s.size.zero? || request_body == body) &&
            headers_match?(request_headers)
        end

        def params_match?(request_params)
          params.keys.all? do |key|
            request_params[key] == params[key]
          end
        end

        def headers_match?(request_headers)
          headers.keys.all? do |key|
            request_headers[key] == headers[key]
          end
        end

        def to_s
          "#{path} #{body}"
        end
      end

      def initialize(app, stubs=nil, &block)
        super(app)
        @stubs = stubs || Stubs.new
        configure(&block) if block
      end

      def configure
        yield(stubs)
      end

      def call(env)
        super
        normalized_path = Faraday::Utils.normalize_path(env[:url])
        params_encoder = env.request.params_encoder || Faraday::Utils.default_params_encoder

        if stub = stubs.match(env[:method], normalized_path, env.request_headers, env[:body])
          env[:params] = (query = env[:url].query) ?
            params_encoder.decode(query)  :
            {}
          status, headers, body = stub.block.call(env)
          save_response(env, status, body, headers)
        else
          raise Stubs::NotFound, "no stubbed request for #{env[:method]} #{normalized_path} #{env[:body]}"
        end
        @app.call(env)
      end
    end
  end
end
