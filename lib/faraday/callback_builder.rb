module Faraday
  # A Builder that processes requests into responses wit
  class CallbackBuilder
    class StackLocked < RuntimeError; end

    attr_reader :current_adapter, :before, :after

    def initialize(adapter = nil, before = nil, after = nil, streaming = nil)
      @before = Array(before)
      @after = Array(after)
      @streaming = Array(streaming)
      @current_adapter = adapter
    end

    def request(key, *args, &block)
      add_before_handler(key, args, block)
    end

    def response(key, *args, &block)
      add_after_handler(key, args, block)
    end

    def streaming_response(key, *args, &block)
      add_streaming_handler(key, args, block)
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
        @streaming.clear
      end
      yield self if block_given?
    end

    def lock!
      @before.freeze
      @after.freeze
      @streaming.freeze
    end

    def locked?
      @before.frozen? || @after.frozen? || @streaming.frozen?
    end

    def on_request(request)
      @before.each { |handler| handler.on_request(self, request) }
    end

    def on_response(response)
      @after.each { |handler| handler.on_response(self, response) }
    end

    def on_response_chunk(response, chunk, size)
      @streaming.each { |handler| handler.on_response_chunk(self, response, chunk, size) }
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

    def add_streaming_handler(*args)
      handler = handler_for(*args)
      @streaming << handler
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

      def on_request(builder, request)
        inner_handler(builder).on_request(request)
      end

      def on_response(builder, response)
        inner_handler(builder).on_response(response)
      end

      def on_response_chunk(builder, response, chunk, size)
        inner_handler(builder).on_response_chunk(response, chunk, size)
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
