# frozen_string_literal: true

module Faraday
  # Extends Connection class to add request building functions.
  class Connection
    # Takes a relative url for a request and combines it with the defaults
    # set on the connection instance.
    #
    # @param url [String]
    # @param extra_params [Hash]
    #
    # @example
    #   conn = Faraday::Connection.new { ... }
    #   conn.url_prefix = "https://sushi.com/api?token=abc"
    #   conn.scheme      # => https
    #   conn.path_prefix # => "/api"
    #
    #   conn.build_url("nigiri?page=2")
    #   # => https://sushi.com/api/nigiri?token=abc&page=2
    #
    #   conn.build_url("nigiri", page: 2)
    #   # => https://sushi.com/api/nigiri?token=abc&page=2
    #
    def build_url(url = nil, extra_params = nil)
      uri = build_exclusive_url(url)

      query_values = params.dup.merge_query(uri.query, options.params_encoder)
      query_values.update(extra_params) if extra_params
      uri.query =
        if query_values.empty?
          nil
        else
          query_values.to_query(options.params_encoder)
        end

      uri
    end

    # Builds and runs the Faraday::Request.
    #
    # @param method [Symbol] HTTP method.
    # @param url [String, URI] String or URI to access.
    # @param body [Object] The request body that will eventually be converted to
    #             a string.
    # @param headers [Hash] unencoded HTTP header key/value pairs.
    #
    # @return [Faraday::Response]
    def run_request(method, url, body, headers)
      unless METHODS.include?(method)
        raise ArgumentError, "unknown http method: #{method}"
      end

      # Resets temp_proxy
      @temp_proxy = proxy_for_request(url)

      request = build_request(method) do |req|
        req.options = req.options.merge(proxy: @temp_proxy)
        req.url(url)                if url
        req.headers.update(headers) if headers
        req.body = body             if body
        yield(req) if block_given?
      end

      builder.build_response(self, request)
    end

    # Creates and configures the request object.
    #
    # @param method [Symbol]
    #
    # @yield [Faraday::Request] if block given
    # @return [Faraday::Request]
    def build_request(method)
      Request.create(method) do |req|
        req.params  = params.dup
        req.headers = headers.dup
        req.options = options
        yield(req) if block_given?
      end
    end

    # Build an absolute URL based on url_prefix.
    #
    # @param url [String, URI]
    # @param params [Faraday::Utils::ParamsHash] A Faraday::Utils::ParamsHash to
    #               replace the query values
    #          of the resulting url (default: nil).
    #
    # @return [URI]
    def build_exclusive_url(url = nil, params = nil, params_encoder = nil)
      url = nil if url.respond_to?(:empty?) && url.empty?
      base = url_prefix
      if url && base.path && base.path !~ %r{/$}
        base = base.dup
        base.path = base.path + '/' # ensure trailing slash
      end
      uri = url ? base + url : base
      if params
        uri.query = params.to_query(params_encoder || options.params_encoder)
      end
      uri.query = nil if uri.query&.empty?
      uri
    end
  end
end
