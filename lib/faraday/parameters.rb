require "forwardable"

module Faraday
  module NestedParamsEncoder
    class << self
      extend Forwardable
      def_delegators :'Faraday::Utils', :escape, :unescape
    end

    def self.encode(params)
      return nil if params == nil

      if !params.is_a?(Array)
        if !params.respond_to?(:to_hash)
          raise TypeError,
            "Can't convert #{params.class} into Hash."
        end
        params = params.to_hash
        params = params.map do |key, value|
          key = key.to_s if key.kind_of?(Symbol)
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
          buffer = ""
          value.each do |key, val|
            new_parent = "#{parent}%5B#{key}%5D"
            buffer << "#{to_query.call(new_parent, val)}&"
          end
          return buffer.chop
        elsif value.is_a?(Array)
          buffer = ""
          value.each_with_index do |val, i|
            new_parent = "#{parent}%5B%5D"
            buffer << "#{to_query.call(new_parent, val)}&"
          end
          return buffer.chop
        else
          encoded_value = escape(value)
          return "#{parent}=#{encoded_value}"
        end
      end

      # The params have form [['key1', 'value1'], ['key2', 'value2']].
      buffer = ''
      params.each do |parent, value|
        encoded_parent = escape(parent)
        buffer << "#{to_query.call(encoded_parent, value)}&"
      end
      return buffer.chop
    end

    def self.decode(query)
      return nil if query == nil
      # Recursive helper lambda
      dehash = lambda do |hash|
        hash.each do |(key, value)|
          if value.kind_of?(Hash)
            hash[key] = dehash.call(value)
          end
        end
        # Numeric keys implies an array
        if hash != {} && hash.keys.all? { |key| key =~ /^\d+$/ }
          hash.sort.inject([]) do |accu, (_, value)|
            accu << value; accu
          end
        else
          hash
        end
      end

      empty_accumulator = {}
      return ((query.split('&').map do |pair|
        pair.split('=', 2) if pair && !pair.empty?
      end).compact.inject(empty_accumulator.dup) do |accu, (key, value)|
        key = unescape(key)
        if value.kind_of?(String)
          value = unescape(value.gsub(/\+/, ' '))
        end

        array_notation = !!(key =~ /\[\]$/)
        subkeys = key.split(/[\[\]]+/)
        current_hash = accu
        for i in 0...(subkeys.size - 1)
          subkey = subkeys[i]
          current_hash[subkey] = {} unless current_hash[subkey]
          current_hash = current_hash[subkey]
        end
        if array_notation
          current_hash[subkeys.last] = [] unless current_hash[subkeys.last]
          current_hash[subkeys.last] << value
        else
          current_hash[subkeys.last] = value
        end
        accu
      end).inject(empty_accumulator.dup) do |accu, (key, value)|
        accu[key] = value.kind_of?(Hash) ? dehash.call(value) : value
        accu
      end
    end
  end

  module FlatParamsEncoder
    class << self
      extend Forwardable
      def_delegators :'Faraday::Utils', :escape, :unescape
    end

    def self.encode(params)
      return nil if params == nil

      if !params.is_a?(Array)
        if !params.respond_to?(:to_hash)
          raise TypeError,
            "Can't convert #{params.class} into Hash."
        end
        params = params.to_hash
        params = params.map do |key, value|
          key = key.to_s if key.kind_of?(Symbol)
          [key, value]
        end
        # Useful default for OAuth and caching.
        # Only to be used for non-Array inputs. Arrays should preserve order.
        params.sort!
      end

      # The params have form [['key1', 'value1'], ['key2', 'value2']].
      buffer = ''
      params.each do |key, value|
        encoded_key = escape(key)
        value = value.to_s if value == true || value == false
        if value == nil
          buffer << "#{encoded_key}&"
        elsif value.kind_of?(Array)
          value.each do |sub_value|
            encoded_value = escape(sub_value)
            buffer << "#{encoded_key}=#{encoded_value}&"
          end
        else
          encoded_value = escape(value)
          buffer << "#{encoded_key}=#{encoded_value}&"
        end
      end
      return buffer.chop
    end

    def self.decode(query)
      empty_accumulator = {}
      return nil if query == nil
      split_query = (query.split('&').map do |pair|
        pair.split('=', 2) if pair && !pair.empty?
      end).compact
      return split_query.inject(empty_accumulator.dup) do |accu, pair|
        pair[0] = unescape(pair[0])
        pair[1] = true if pair[1].nil?
        if pair[1].respond_to?(:to_str)
          pair[1] = unescape(pair[1].to_str.gsub(/\+/, " "))
        end
        if accu[pair[0]].kind_of?(Array)
          accu[pair[0]] << pair[1]
        elsif accu[pair[0]]
          accu[pair[0]] = [accu[pair[0]], pair[1]]
        else
          accu[pair[0]] = pair[1]
        end
        accu
      end
    end
  end
end
