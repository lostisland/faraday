# frozen_string_literal: true

module Faraday
  # Env holds the state of one request and its response while it goes through
  # the middleware stack.
  #
  # Middleware reads and writes it with the accessors or with {#[]} and
  # {#[]=}. Keys that are not members are kept as custom members, see
  # {#custom_members}.
  #
  # The +body+ key means the request body until the response has a status,
  # and the response body after that, see {#body}. {.from}, {#update},
  # {#merge} and {#[]} accept it too.
  #
  # {.from}, {#update} and {#merge} coerce +request+ to {RequestOptions},
  # +ssl+ to {SSLOptions}, and +request_headers+ and +response_headers+ to
  # {Utils::Headers}. +false+ means "not set" for these members: they skip it
  # and keep the current value. The writers and {#[]=} keep the assigned value
  # as it is.
  class Env < BaseOptions
    extend Forwardable

    MEMBERS = %i[
      method request_body url request request_headers ssl parallel_manager
      params response response_headers status reason_phrase response_body
    ].freeze

    COERCIONS = {
      request: RequestOptions,
      request_headers: Utils::Headers,
      response_headers: Utils::Headers,
      ssl: SSLOptions
    }.freeze

    # The names are public API, so they keep the CamelCase of the legacy Struct.
    ContentLength = 'Content-Length' # rubocop:disable Naming/ConstantName
    StatusesWithoutBody = Set.new([204, 304])
    SuccessfulStatuses = (200..299) # rubocop:disable Naming/ConstantName

    # A Set of HTTP verbs that typically send a body. If no body is set for
    # these requests, the Content-Length header is set to 0.
    MethodsWithBodies = Set.new(Faraday::METHODS_WITH_BODY.map(&:to_sym))

    # @return [Symbol] HTTP method (+:get+, +:post+)
    attr_accessor :method

    # @return [String, Hash] the request body, which middleware eventually
    #   converts to a String
    attr_accessor :request_body

    # @return [URI] URI instance for the current request
    attr_accessor :url

    # @return [RequestOptions] options for configuring the request
    attr_accessor :request

    # @return [Utils::Headers] HTTP headers to be sent to the server
    attr_accessor :request_headers

    # @return [SSLOptions] options for configuring SSL requests
    attr_accessor :ssl

    # @return [Object] set if the connection is in parallel mode
    attr_accessor :parallel_manager

    # @return [Hash] the request params
    attr_accessor :params

    # @return [Response] the response, once the adapter has made one
    attr_accessor :response

    # @return [Utils::Headers] HTTP headers from the server
    attr_accessor :response_headers

    # @return [Integer] HTTP response status code
    attr_accessor :status

    # @return [String] the reason phrase of the response status
    attr_accessor :reason_phrase

    # @return [Object] the response body
    attr_accessor :response_body

    def_delegators :request, :params_encoder

    # Builds a new Env from a Hash or from another Env.
    #
    # A copy of an Env gets new {RequestOptions}, {SSLOptions}, headers and
    # Hash values, and the same custom members. Other values are shared with
    # the original.
    #
    # @param value [nil, Hash, Env] the values of the new Env
    # @return [Env]
    def self.from(value)
      return super unless value.is_a?(Env)

      env = new(value.to_hash.transform_values { |v| v.is_a?(Hash) ? v.dup : v })
      env.custom_members.update(value.custom_members)
      env
    end

    # Builds the Env of a request. The request options, the request headers
    # and the SSL options of the connection are used as they are, not copied.
    #
    # @param request [Request]
    # @param url [URI] the full URL of the request
    # @param connection [Connection]
    # @return [Env]
    # @api private
    def self.for_request(request, url, connection)
      env = new
      env.method = request.http_method
      env.request_body = request.body
      env.url = url
      env.request = request.options
      env.request_headers = request.headers
      env.ssl = connection.ssl
      env.parallel_manager = connection.parallel_manager
      env
    end

    # @param key [Symbol, String] a member, +:body+ or a custom member
    # @return [Object] the value, or +nil+ if a custom member is not set
    def [](key)
      member = member_for(key)
      member ? public_send(member) : custom_members[key]
    end

    # @param key [Symbol, String] a member, +:body+ or a custom member
    # @param value [Object] the value, which is not coerced
    def []=(key, value)
      member = member_for(key)
      if member
        public_send(:"#{member}=", value)
      else
        custom_members[key] = value
      end
    end

    # Unsets a member or removes a custom member.
    #
    # @param key [Symbol, String] a member, +:body+ or a custom member
    # @return [Object] the value before the deletion
    def delete(key)
      member = member_for(key)
      return custom_members.delete(key) unless member

      value = public_send(member)
      public_send(:"#{member}=", nil)
      value
    end

    # Reads +key+, then calls +dig+ on the value with the other keys.
    #
    # @example
    #   env.dig(:response_headers, 'Content-Type')
    def dig(key, *keys)
      value = self[key]
      keys.empty? || value.nil? ? value : value.dig(*keys)
    end

    # @return [Symbol] +:response_body+ if the response has a status,
    #   +:request_body+ otherwise
    def current_body
      status ? :response_body : :request_body
    end

    # @return [Object] the request body, or the response body once the
    #   response has a status
    def body
      self[:body]
    end

    # Sets the request body, or the response body once the response has a
    # status.
    def body=(value)
      self[:body] = value
    end

    # @return [Boolean] true if status is in the set of {SuccessfulStatuses}.
    def success?
      SuccessfulStatuses.include?(status)
    end

    # @return [Boolean] true if there's no body yet, and the method is in the
    #   set of {MethodsWithBodies}.
    def needs_body?
      !body && MethodsWithBodies.include?(method)
    end

    # Sets content length to zero and the body to the empty string.
    def clear_body
      request_headers[ContentLength] = '0'
      self.body = +''
    end

    # @return [Boolean] true if the status isn't in the set of
    #   {StatusesWithoutBody}.
    def parse_body?
      !StatusesWithoutBody.include?(status)
    end

    # @return [Boolean] true if there is a parallel_manager
    def parallel?
      !!parallel_manager
    end

    # @return [Boolean] true if the request options have an +on_data+ callback
    def stream_response?
      request.stream_response?
    end

    # Calls the +on_data+ callback of the request options with each chunk
    # that the block yields, and once with an empty chunk if there is none.
    #
    # @yield [chunk_handler] the block that reads the response
    # @return [Object] the value of the block
    def stream_response(&block)
      size = 0
      yielded = false
      block_result = block.call do |chunk|
        if chunk.bytesize.positive? || size.positive?
          yielded = true
          size += chunk.bytesize
          request.on_data.call(chunk, size, self)
        end
      end
      request.on_data.call(+'', 0, self) unless yielded
      block_result
    end

    # The values of the keys that are not members, set with {#[]=}.
    #
    # @return [Hash]
    def custom_members
      @custom_members ||= {}
    end

    # Members only, nested options objects stay objects, like the legacy
    # Struct. Custom members are not included.
    #
    # @return [Hash]
    def to_hash
      MEMBERS.each_with_object({}) do |key, hash|
        value = public_send(key)
        hash[key] = value unless value.nil?
      end
    end

    # @return [Env] a deep copy, with a deep copy of the custom members
    def deep_dup
      copy = super
      copy.custom_members.update(Utils.deep_dup(custom_members))
      copy
    end

    def inspect
      attrs = [nil]
      MEMBERS.each do |member|
        if (value = public_send(member))
          attrs << "@#{member}=#{value.inspect}"
        end
      end
      attrs << "@custom=#{custom_members.inspect}" unless custom_members.empty?
      %(#<#{self.class}#{attrs.join(' ')}>)
    end

    private

    # Returns the member for +key+, +nil+ for a custom member. The +:body+
    # key is the current body.
    def member_for(key)
      return current_body if key == :body
      return unless key.is_a?(Symbol) || key.is_a?(String)

      member = key.to_sym
      member if MEMBERS.include?(member)
    end

    # Accepts the +body+ key, see {#current_body}. The current body is read
    # for each key, so a +status+ before +body+ makes it the response body.
    def each_option(obj, &block)
      obj = obj.to_hash if obj.respond_to?(:to_hash)
      obj.each do |key, value|
        if key.to_s == 'body'
          yield current_body, value unless value.nil?
        else
          super({ key => value }, &block)
        end
      end
    end

    # Skips +false+ for the coerced members, see the class documentation.
    def write(key, value)
      super unless value == false && COERCIONS.key?(key)
    end
  end
end
