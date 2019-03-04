# frozen_string_literal: true

module Faraday
  # This is the default encoder for Faraday requests.
  # Using this encoder, parameters will be encoded respecting their structure,
  # so you can send objects such as Arrays or Hashes as parameters for your requests.
  module NestedParamsEncoder
    class << self
      extend Forwardable
      def_delegators :'Faraday::Utils', :escape, :unescape
    end

    extend self

    # @param params [nil, Array, #to_hash] parameters to be encoded
    #
    # @return [String] the encoded params
    #
    # @raise [TypeError] if params can not be converted to a Hash
    def encode(params)
      return nil if params.nil?

      unless params.is_a?(Array)
        unless params.respond_to?(:to_hash)
          raise TypeError,
                "Can't convert #{params.class} into Hash."
        end
        params = params.to_hash
        params = params.map do |key, value|
          key = key.to_s if key.is_a?(Symbol)
          [key, value]
        end
        # Useful default for OAuth and caching.
        # Only to be used for non-Array inputs. Arrays should preserve order.
        params.sort!
      end

      # The params have form [['key1', 'value1'], ['key2', 'value2']].
      buffer = +''
      params.each do |parent, value|
        encoded_parent = escape(parent)
        buffer << "#{encode_pair(encoded_parent, value)}&"
      end
      buffer.chop
    end

    # @param query [nil, String]
    #
    # @return [Array<Array, String>] the decoded params
    #
    # @raise [TypeError] if the nesting is incorrect
    def decode(query)
      return nil if query.nil?

      params = {}
      query.split('&').each do |pair|
        next if pair.empty?

        key, value = pair.split('=', 2)
        key = unescape(key)
        value = unescape(value.tr('+', ' ')) if value
        decode_pair(key, value, params)
      end

      dehash(params, 0)
    end

    private

    SUBKEYS_REGEX = /[^\[\]]+(?:\]?\[\])?/.freeze

    # Internal: convert a nested hash with purely numeric keys into an array.
    # FIXME: this is not compatible with Rack::Utils.parse_nested_query
    # @!visibility private
    def dehash(hash, depth)
      hash.each { |key, value| hash[key] = dehash(value, depth + 1) if value.is_a?(Hash) }

      if depth.positive? && !hash.empty? && hash.keys.all? { |k| k =~ /^\d+$/ }
        hash.keys.sort.inject([]) { |all, key| all << hash[key] }
      else
        hash
      end
    end

    def encode_pair(parent, value)
      if value.is_a?(Hash)
        encode_hash(parent, value)
      elsif value.is_a?(Array)
        encode_array(parent, value)
      elsif value.nil?
        parent
      else
        encoded_value = escape(value)
        "#{parent}=#{encoded_value}"
      end
    end

    def encode_hash(parent, value)
      value = value.map { |key, val| [escape(key), val] }.sort

      buffer = +''
      value.each do |key, val|
        new_parent = "#{parent}%5B#{key}%5D"
        buffer << "#{encode_pair(new_parent, val)}&"
      end
      buffer.chop
    end

    def encode_array(parent, value)
      new_parent = "#{parent}%5B%5D"
      return new_parent if value.empty?

      buffer = +''
      value.each { |val| buffer << "#{encode_pair(new_parent, val)}&" }
      buffer.chop
    end

    def decode_pair(key, value, context)
      subkeys = key.scan(SUBKEYS_REGEX)
      subkeys.each_with_index do |subkey, i|
        is_array = subkey =~ /[\[\]]+\Z/
        subkey = $` if is_array
        last_subkey = i == subkeys.length - 1

        if !last_subkey || is_array
          value_type = is_array ? Array : Hash
          raise TypeError, format("expected #{value_type.name} (got #{context[subkey].class.name}) for param `#{subkey}'") if context[subkey] && !context[subkey].is_a?(value_type)

          context = (context[subkey] ||= value_type.new)
        end

        if context.is_a?(Array) && !is_array
          context << {} if !context.last.is_a?(Hash) || context.last.key?(subkey)
          context = context.last
        end

        if last_subkey
          if is_array
            context << value
          else
            context[subkey] = value
          end
        end
      end
    end
  end
end
