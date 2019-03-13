# frozen_string_literal: true

module Faraday
  # Set of helpers for Faraday::Options.
  module OptionsHelpers
    # Public
    def each
      return to_enum(:each) unless block_given?

      members.each do |key|
        yield(key.to_sym, send(key))
      end
    end

    # Public
    def values_at(*keys)
      keys.map { |key| send(key) }
    end

    # Public
    def keys
      members.reject { |member| send(member).nil? }
    end

    # Public
    def empty?
      keys.empty?
    end

    # Public
    def each_key
      return to_enum(:each_key) unless block_given?

      keys.each do |key|
        yield(key)
      end
    end

    # Public
    def key?(key)
      keys.include?(key)
    end

    alias has_key? key?

    # Public
    def each_value
      return to_enum(:each_value) unless block_given?

      values.each do |value|
        yield(value)
      end
    end

    # Public
    def value?(value)
      values.include?(value)
    end

    alias has_value? value?

    # Public
    def to_hash
      hash = {}
      members.each do |key|
        value = send(key)
        hash[key.to_sym] = value unless value.nil?
      end
      hash
    end

    # Internal
    def inspect
      values = []
      members.each do |member|
        value = send(member)
        values << "#{member}=#{value.inspect}" if value
      end
      values = values.empty? ? ' (empty)' : (' ' << values.join(', '))

      %(#<#{self.class}#{values}>)
    end

    def symbolized_key_set
      @symbolized_key_set ||= Set.new(keys.map(&:to_sym))
    end
  end
end
