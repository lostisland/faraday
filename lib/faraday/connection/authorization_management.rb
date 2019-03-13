# frozen_string_literal: true

module Faraday
  # Extends Connection class to add authorization management functions.
  class Connection
    # Sets up the Authorization header with these credentials, encoded
    # with base64.
    #
    # @param login [String] The authentication login.
    # @param pass [String] The authentication password.
    #
    # @example
    #
    #   conn.basic_auth 'Aladdin', 'open sesame'
    #   conn.headers['Authorization']
    #   # => "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=="
    #
    # @return [void]
    def basic_auth(login, pass)
      set_authorization_header(:basic_auth, login, pass)
    end

    # Sets up the Authorization header with the given token.
    #
    # @param token [String]
    # @param options [Hash] extra token options.
    #
    # @example
    #
    #   conn.token_auth 'abcdef', foo: 'bar'
    #   conn.headers['Authorization']
    #   # => "Token token=\"abcdef\",
    #               foo=\"bar\""
    #
    # @return [void]
    def token_auth(token, options = nil)
      set_authorization_header(:token_auth, token, options)
    end

    # Sets up a custom Authorization header.
    #
    # @param type [String] authorization type
    # @param token [String, Hash] token. A String value is taken literally, and
    #         a Hash is encoded into comma-separated key/value pairs.
    #
    # @example
    #
    #   conn.authorization :Bearer, 'mF_9.B5f-4.1JqM'
    #   conn.headers['Authorization']
    #   # => "Bearer mF_9.B5f-4.1JqM"
    #
    #   conn.authorization :Token, token: 'abcdef', foo: 'bar'
    #   conn.headers['Authorization']
    #   # => "Token token=\"abcdef\",
    #               foo=\"bar\""
    #
    # @return [void]
    def authorization(type, token)
      set_authorization_header(:authorization, type, token)
    end

    def set_authorization_header(header_type, *args)
      header = Faraday::Request
               .lookup_middleware(header_type)
               .header(*args)

      headers[Faraday::Request::Authorization::KEY] = header
    end
  end
end
