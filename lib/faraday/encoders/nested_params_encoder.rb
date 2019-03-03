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

    # @param params [nil, Array, #to_hash] parameters to be encoded
    #
    # @return [String] the encoded params
    #
    # @raise [TypeError] if params can not be converted to a Hash
    def self.encode(params)
      return nil if params == nil

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

      # Helper lambda
      to_query = lambda do |parent, value|
        if value.is_a?(Hash)
          value = value.map do |key, val|
            key = escape(key)
            [key, val]
          end
          value.sort!
          buffer = +''
          value.each do |key, val|
            new_parent = "#{parent}%5B#{key}%5D"
            buffer << "#{to_query.call(new_parent, val)}&"
          end
          return buffer.chop
        elsif value.is_a?(Array)
          new_parent = "#{parent}%5B%5D"
          return new_parent if value.empty?

          buffer = +''
          value.each do |val|
            buffer << "#{to_query.call(new_parent, val)}&"
          end
          return buffer.chop
        elsif value.nil?
          return parent
        else
          encoded_value = escape(value)
          return "#{parent}=#{encoded_value}"
        end
      end

      # The params have form [['key1', 'value1'], ['key2', 'value2']].
      buffer = +''
      params.each do |parent, value|
        encoded_parent = escape(parent)
        buffer << "#{to_query.call(encoded_parent, value)}&"
      end
      buffer.chop
    end

    # @param query [nil, String]
    #
    # @return [Array<Array, String>] the decoded params
    #
    # @raise [TypeError] if the nesting is incorrect
    def self.decode(query)
      return nil if query == nil

      params = {}
      query.split('&').each do |pair|
        next if pair.empty?

        key, value = pair.split('=', 2)
        key = unescape(key)
        value = unescape(value.tr('+', ' ')) if value

        subkeys = key.scan(/[^\[\]]+(?:\]?\[\])?/)
        context = params
        subkeys.each_with_index do |subkey, i|
          is_array = subkey =~ /[\[\]]+\Z/
          subkey = $` if is_array
          last_subkey = i == subkeys.length - 1

          if !last_subkey || is_array
            value_type = is_array ? Array : Hash
            if context[subkey] && !context[subkey].is_a?(value_type)
              raise TypeError, format("expected #{value_type.name} (got #{context[subkey].class.name}) for param `#{subkey}'")
            end

            context = (context[subkey] ||= value_type.new)
          end

          if context.is_a?(Array) && !is_array
            if !context.last.is_a?(Hash) || context.last.has_key?(subkey)
              context << {}
            end
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

      dehash(params, 0)
    end

    # Internal: convert a nested hash with purely numeric keys into an array.
    # FIXME: this is not compatible with Rack::Utils.parse_nested_query
    # @!visibility private
    def self.dehash(hash, depth)
      hash.each do |key, value|
        hash[key] = dehash(value, depth + 1) if value.is_a?(Hash)
      end

      if depth > 0 && !hash.empty? && hash.keys.all? { |k| k =~ /^\d+$/ }
        hash.keys.sort.inject([]) { |all, key| all << hash[key] }
      else
        hash
      end
    end
  end
end
