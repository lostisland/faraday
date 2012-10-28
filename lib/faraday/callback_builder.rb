module Faraday
  # A Builder that processes requests into responses wit
  class CallbackBuilder
    class StackLocked < RuntimeError; end

    attr_reader :current_adapter, :before, :after

    def initialize(adapter = nil, before = nil, after = nil)
      @before = Array(before)
      @after = Array(after)
      @current_adapter = adapter
    end

    def request(key, *args, &block)
      add_before_handler(key, args, block)
    end

    def response(key, *args, &block)
      add_after_handler(key, args, block)
    end

    def adapter(key, *args, &block)
      set_adapter_handler(key, args, block)
    end

    def build_response(connection, request)
      @current_adapter.call(self, request)
    end

    def build(options = nil)
      raise_if_locked
      unless options && options[:keep]
        @before.clear
        @after.clear
      end
      yield self if block_given?
    end

    def lock!
      @before.freeze
      @after.freeze
    end

    def locked?
      @before.frozen? || @after.frozen?
    end

    def run_request_callbacks(request)
      @before.each { |handler| handler.on_request(self, request) }
    end

    def run_response_callbacks(response)
      @after.each { |handler| handler.on_response(self, response) }
    end

  private

    def add_before_handler(*args)
      handler = handler_for(*args)
      @before << handler
    end

    def add_after_handler(*args)
      handler = handler_for(*args)
      @after << handler
    end

    def set_adapter_handler(*args)
      handler = handler_for(*args)
      @current_adapter = handler
    end

    def handler_for(key, args, block)
      Handler.new(key, args, block)
    end

    def raise_if_locked
      raise StackLocked, "can't modify middleware stack after making a request" if locked?
    end

    class Handler < Struct.new(:klass, :args, :block)
      class Invalid < RuntimeError; end
      class BuilderMismatch < RuntimeError; end

      def on_request(builder, req)
        inner_handler(builder).on_request(req)
      end

      def on_response(builder, res)
        inner_handler(builder).on_response(res)
      end

      def call(builder, req)
        inner_handler(builder).call(req)
      end

      def inner_handler(builder)
        if @inner_handler
          if builder != @inner_handler.builder
            raise BuilderMismatch, "Builders don't match"
          end
          @inner_handler
        else
          @inner_handler = klass.new(builder, *args, &block)
        end
      end

    private
      def raise_if_builder_mismatch(builder)
        raise BuilderMismatch, "Builders don't match" if builder != inner_handler.builder
      end
    end
  end
end
