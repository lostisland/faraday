# frozen_string_literal: true

module Faraday
  # @!parse
  #   # ConnectionOptions contains the configurable properties for a Faraday
  #   # connection object.
  #   #
  #   # @!attribute request
  #   #   @return [RequestOptions] default request options for the connection
  #   #
  #   # @!attribute proxy
  #   #   @return [ProxyOptions] proxy options for the connection
  #   #
  #   # @!attribute ssl
  #   #   @return [SSLOptions] SSL options for the connection
  #   #
  #   # @!attribute builder
  #   #   @return [RackBuilder] the middleware stack builder for the connection
  #   #
  #   # @!attribute url
  #   #   @return [String, URI] the base URL for the connection
  #   #
  #   # @!attribute parallel_manager
  #   #   @return [Object] manager used when the connection runs in parallel mode
  #   #
  #   # @!attribute params
  #   #   @return [Hash] default query parameters for the connection
  #   #
  #   # @!attribute headers
  #   #   @return [Hash] default headers for the connection
  #   #
  #   # @!attribute builder_class
  #   #   @return [Class] the class used to build the middleware stack
  #   class ConnectionOptions < Options; end
  ConnectionOptions = Options.new(:request, :proxy, :ssl, :builder, :url,
                                  :parallel_manager, :params, :headers,
                                  :builder_class) do
    options request: RequestOptions, ssl: SSLOptions

    memoized(:request) { self.class.options_for(:request).new }

    memoized(:ssl) { self.class.options_for(:ssl).new }

    memoized(:builder_class) { RackBuilder }

    def new_builder(block)
      builder_class.new(&block)
    end
  end
end
