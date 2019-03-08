# frozen_string_literal: true

module Faraday
  class RequestOptions < Options.new(:params_encoder, :proxy, :bind,
                                     :timeout, :open_timeout, :write_timeout,
                                     :boundary, :oauth, :context, :on_data)

    def []=(key, value)
      if key && key.to_sym == :proxy
        super(key, value ? ProxyOptions.from(value) : nil)
      else
        super(key, value)
      end
    end

    def stream_response?
      on_data.is_a?(Proc)
    end
  end
end
