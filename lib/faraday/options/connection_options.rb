# frozen_string_literal: true

module Faraday
  # ConnectionOptions contains the configurable properties for a Faraday
  # connection object.
  #
  # The +request+, +ssl+ and +proxy+ values are coerced by {.from}, {#update}
  # and {#merge}. A falsy value means "not set", like the legacy Struct did:
  # +request+ and +ssl+ then return new default instances, and +proxy+ is +nil+.
  # The writers keep the assigned value as it is.
  class ConnectionOptions < BaseOptions
    MEMBERS = %i[
      request proxy ssl builder url parallel_manager params headers builder_class
    ].freeze

    COERCIONS = {
      request: ->(value) { value ? RequestOptions.from(value) : nil },
      proxy: ->(value) { value ? ProxyOptions.from(value) : nil },
      ssl: ->(value) { value ? SSLOptions.from(value) : nil }
    }.freeze

    # @return [ProxyOptions] proxy options for the connection
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
  end
end
