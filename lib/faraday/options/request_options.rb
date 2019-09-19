# frozen_string_literal: true

module Faraday
  # RequestOptions contains the configurable properties for a Faraday request.
  class RequestOptions < Options.new(:params_encoder, :proxy, :bind,
                                     :timeout, :open_timeout, :read_timeout,
                                     :write_timeout, :boundary, :oauth,
                                     :context, :on_data)

    def []=(key, value)
      if key && key.to_sym == :proxy
        super(key, value ? ProxyOptions.from(value) : nil)
      else
        super(key, value)
      end
    end

    # Fetches either a read, write, or open timeout setting. Defaults to the
    # :timeout value if a more specific one is not given.
    #
    # @param type [Symbol] Describes which timeout setting to get: :read,
    #                      :write, or :open.
    #
    # @return [Integer, nil] Timeout duration in seconds, or nil if no timeout
    #                        has been set.
    def fetch_timeout(type)
      unless TIMEOUT_TYPES.include?(type)
        msg = "Expected :read, :write, :open. Got #{type.inspect} :("
        raise ArgumentError, msg
      end

      self["#{type}_timeout".to_sym] || self[:timeout]
    end

    def stream_response?
      on_data.is_a?(Proc)
    end

    TIMEOUT_TYPES = Set.new(%i[read write open])
  end
end
