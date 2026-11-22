# frozen_string_literal: true

module Faraday
  # RequestOptions contains the configurable properties for a Faraday request.
  class RequestOptions < BaseOptions
    include StructCompat

    MEMBERS = %i[
      params_encoder proxy bind timeout open_timeout read_timeout write_timeout
      boundary oauth context on_data
    ].freeze

    # A falsy proxy means no proxy, like the legacy +[]=+ did.
    COERCIONS = { proxy: ->(value) { value ? ProxyOptions.from(value) : nil } }.freeze

    # @return [Object] the params encoder used to serialize the request params
    attr_accessor :params_encoder

    # @return [ProxyOptions, nil] proxy options for this request. {.from},
    #   {#update} and {#merge} coerce the value to {ProxyOptions} (+nil+ if it
    #   is falsy), the +proxy=+ writer does not.
    attr_accessor :proxy

    # @return [Hash] the local host and port to bind the connection to
    attr_accessor :bind

    # @return [Integer] time limit for the entire request (in seconds)
    attr_accessor :timeout

    # @return [Integer] time limit for just the connection phase (in seconds)
    attr_accessor :open_timeout

    # @return [Integer] time limit for the first response byte received from
    #   the server (in seconds)
    attr_accessor :read_timeout

    # @return [Integer] time limit for the client to send the request to the
    #   server (in seconds)
    attr_accessor :write_timeout

    # @return [String] the boundary used for multipart request bodies
    attr_accessor :boundary

    # @return [Hash] OAuth options used by the OAuth middleware
    attr_accessor :oauth

    # @return [Hash] free-form storage carried alongside the request
    attr_accessor :context

    # @return [Proc] callback invoked with each chunk when streaming the response
    attr_accessor :on_data

    def stream_response?
      on_data.is_a?(Proc)
    end
  end
end
