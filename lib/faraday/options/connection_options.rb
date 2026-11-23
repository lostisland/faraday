# frozen_string_literal: true

module Faraday
  # ConnectionOptions contains the configurable properties for a Faraday
  # connection object.
  #
  # The +request+, +ssl+ and +proxy+ values are coerced by {.from}, {#update}
  # and {#merge}. +false+ means "not set" for these members, like the legacy
  # Struct did: {.from}, {#update} and {#merge} skip it and keep the current
  # value. The writers keep the assigned value as it is.
  #
  # The +request+, +ssl+ and +builder_class+ readers assign a default when no
  # value is set, so {#to_hash} always includes them.
  class ConnectionOptions < BaseOptions
    MEMBERS = %i[
      request proxy ssl builder url parallel_manager params headers builder_class
    ].freeze

    COERCIONS = {
      request: RequestOptions,
      proxy: ProxyOptions,
      ssl: SSLOptions
    }.freeze

    # @return [ProxyOptions, nil] proxy options for the connection
    attr_accessor :proxy

    # @return [RackBuilder] the middleware stack builder for the connection
    attr_accessor :builder

    # @return [String, URI] the base URL for the connection
    attr_accessor :url

    # @return [Object] manager used when the connection runs in parallel mode
    attr_accessor :parallel_manager

    # @return [Hash] default query parameters for the connection
    attr_accessor :params

    # @return [Hash] default headers for the connection
    attr_accessor :headers

    attr_writer :request, :ssl, :builder_class

    # @return [RequestOptions] default request options for the connection.
    #   A new instance is assigned when none is set.
    def request
      @request ||= RequestOptions.new
    end

    # @return [SSLOptions] SSL options for the connection.
    #   A new instance is assigned when none is set.
    def ssl
      @ssl ||= SSLOptions.new
    end

    # @return [Class] the class used to build the middleware stack.
    #   {RackBuilder} is assigned when none is set.
    def builder_class
      @builder_class ||= RackBuilder
    end

    # Builds a new middleware stack with {#builder_class}.
    #
    # @param block [Proc, nil] the block passed to the builder
    # @return [RackBuilder]
    def new_builder(block)
      builder_class.new(&block)
    end

    private

    # Skips +false+ for the coerced members, see the class documentation.
    def write(key, value)
      super unless value == false && COERCIONS.key?(key)
    end
  end
end
