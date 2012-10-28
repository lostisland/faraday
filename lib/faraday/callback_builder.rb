module Faraday
  # A Builder that processes requests into responses wit
  class CallbackBuilder
    class StackLocked < RuntimeError; end

    attr_reader :current_adapter, :before, :after, :has_streaming_callbacks

    def initialize(adapter = nil, before = nil, after = nil, streaming = nil)
      @before = Array(before)
      @after = Array(after)
      @streaming = Array(streaming)
      @current_adapter = adapter
      @has_streaming_callbacks = nil
    end

    def request(key, *args, &block)
      raise_if_locked
      @before << Handler.new(key, args, block)
    end

    def response(key, *args, &block)
      raise_if_locked
      @after << Handler.new(key, args, block)
    end

    def streaming_response(key, *args, &block)
      raise_if_locked
      @streaming << Handler.new(key, args, block)
    end

    def adapter(key, *args, &block)
      @current_adapter = Handler.new(key, args, block)
    end

    def build_response(connection, request)
      lock!
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
      [
        [@before, :request], [@after, :response], [@streaming, :response_chunk]
      ].each do |(callbacks, suffix)|
        callbacks.freeze

        # make this check once
        if suffix == :response_chunk
          @has_streaming_callbacks = callbacks.size > 0
        end

        # turn callbacks into no-ops if there are no callbacks
        if callbacks.empty?
          meta_class.send(:alias_method, "on_#{suffix}", :callback_noop)
        end
      end

      # don't lock a builder twice
      meta_class.send(:alias_method, :lock!, :lock_noop)
      meta_class.send(:alias_method, :locked?, :lock_noop)
    end

    def locked?
      false
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

    alias streaming_callbacks? has_streaming_callbacks

    def callback_noop(a, b = nil, c = nil)
    end

    def lock_noop
      true
    end

  private

    def meta_class
      @meta_class ||= class << self; self; end
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
        @inner_handler ||= klass.new(*args, &block)
        ensure_builder(builder) if @inner_handler.respond_to?(:builder)
        @inner_handler
      end

    private
      def ensure_builder(builder)
        if set_builder = @inner_handler.builder
          if builder != set_builder
            raise BuilderMismatch, "Builders don't match"
          end
        else
          @inner_handler.builder = builder
        end
      end
    end
  end
end

