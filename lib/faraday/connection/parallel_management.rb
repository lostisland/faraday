# frozen_string_literal: true

module Faraday
  # Extends Connection class to add parallel management functions.
  class Connection
    # Check if the adapter is parallel-capable.
    #
    # @yield if the adapter isn't parallel-capable, or if no adapter is set yet.
    #
    # @return [Object, nil] a parallel manager or nil if yielded
    # @api private
    def default_parallel_manager
      @default_parallel_manager ||= begin
        adapter = @builder.adapter.klass if @builder.adapter

        if support_parallel?(adapter)
          adapter.setup_parallel_manager
        elsif block_given?
          yield
        end
      end
    end

    # Determine if this Faraday::Connection can make parallel requests.
    #
    # @return [Boolean]
    def in_parallel?
      !!@parallel_manager
    end

    # Sets up the parallel manager to make a set of requests.
    #
    # @param manager [Object] The parallel manager that this Connection's
    #                Adapter uses.
    #
    # @yield a block to execute multiple requests.
    # @return [void]
    def in_parallel(manager = nil)
      @parallel_manager = manager || default_parallel_manager do
        warn 'Warning: `in_parallel` called but no parallel-capable adapter ' \
             'on Faraday stack'
        warn caller[2, 10].join("\n")
        nil
      end
      yield
      @parallel_manager&.run
    ensure
      @parallel_manager = nil
    end

    def support_parallel?(adapter)
      adapter&.respond_to?(:supports_parallel?) && adapter&.supports_parallel?
    end
  end
end
