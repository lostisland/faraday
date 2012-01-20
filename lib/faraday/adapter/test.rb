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
          yield self if block_given?
        end

        def empty?
          @stack.empty?
        end

        def match(request_method, path, body)
          return false if !@stack.key?(request_method)
          stack = @stack[request_method]
          consumed = (@consumed[request_method] ||= [])
          path = normalize_path(path)

          if stub = matches?(stack, path, body)
            consumed << stack.delete(stub)
            stub
          else
            matches?(consumed, path, body)
          end
        end

        def get(path, &block)
          new_stub(:get, path, &block)
        end

        def head(path, &block)
          new_stub(:head, path, &block)
        end

        def post(path, body=nil, &block)
          new_stub(:post, path, body, &block)
        end

        def put(path, body=nil, &block)
          new_stub(:put, path, body, &block)
        end

        def patch(path, body=nil, &block)
          new_stub(:patch, path, body, &block)
        end

        def delete(path, &block)
          new_stub(:delete, path, &block)
        end

        def options(path, &block)
          new_stub(:options, path, &block)
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

        def new_stub(request_method, path, body=nil, &block)
          (@stack[request_method] ||= []) << Stub.new(normalize_path(path), body, block)
        end

        def matches?(stack, path, body)
          stack.detect { |stub| stub.matches?(path, body) }
        end

        # ensure leading + trailing slash
        def normalize_path(path)
          path = '/' + path if path.index('/') != 0
          path = path.sub('?', '/?')
          path = path + '/' unless $&
          path.gsub('//', '/')
        end
      end

      class Stub < Struct.new(:path, :params, :body, :block)
        def initialize(full, body, block)
          path, query = full.split('?')
          params = query ?
            Faraday::Utils.parse_nested_query(query) :
            {}
          super path, params, body, block
        end

        def matches?(request_uri, request_body)
          request_path, request_query = request_uri.split('?')
          request_params = request_query ?
            Faraday::Utils.parse_nested_query(request_query) :
            {}
          request_path == path &&
            params_match?(request_params) &&
            (body.to_s.size.zero? || request_body == body)
        end

        def params_match?(request_params)
          params.keys.all? do |key|
            request_params[key] == params[key]
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
        yield stubs
      end

      def call(env)
        super
        normalized_path = Faraday::Utils.normalize_path(env[:url])

        if stub = stubs.match(env[:method], normalized_path, env[:body])
          env[:params] = (query = env[:url].query) ?
            Faraday::Utils.parse_nested_query(query)  :
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
