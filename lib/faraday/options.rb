# frozen_string_literal: true

require 'faraday/options/options_helpers'

module Faraday
  # Subclasses Struct with some special helpers for converting
  # from a Hash to a Struct.
  class Options < Struct
    include Faraday::OptionsHelpers

    # Public
    def self.from(value)
      value ? new.update(value) : new
    end

    def [](key)
      key = key.to_sym
      if (method = self.class.memoized_attributes[key])
        super(key) || (self[key] = instance_eval(&method))
      else
        super
      end
    end

    # Public
    def update(obj)
      obj.each do |key, value|
        sub_options = self.class.options_for(key)
        if sub_options
          new_value = sub_options.from(value) if value
        elsif value.is_a?(Hash)
          new_value = value.dup
        else
          new_value = value
        end

        send("#{key}=", new_value) unless new_value.nil?
      end
      self
    end

    # Public
    def delete(key)
      value = send(key)
      send("#{key}=", nil)
      value
    end

    # Public
    def clear
      members.each { |member| delete(member) }
    end

    # Public
    def merge!(other)
      other.each do |key, other_value|
        self_value = send(key)
        sub_options = self.class.options_for(key)
        new_value = if self_value && sub_options && other_value
                      self_value.merge(other_value)
                    else
                      other_value
                    end
        send("#{key}=", new_value) unless new_value.nil?
      end
      self
    end

    # Public
    def merge(other)
      dup.merge!(other)
    end

    # Public
    def deep_dup
      self.class.from(self)
    end

    # Public
    def fetch(key, *args)
      unless symbolized_key_set.include?(key.to_sym)
        key_setter = "#{key}="
        if !args.empty?
          send(key_setter, args.first)
        elsif block_given?
          send(key_setter, Proc.new.call(key))
        else
          raise self.class.fetch_error_class, "key not found: #{key.inspect}"
        end
      end
      send(key)
    end

    # Internal
    def self.options(mapping)
      attribute_options.update(mapping)
    end

    # Internal
    def self.options_for(key)
      attribute_options[key]
    end

    # Internal
    def self.attribute_options
      @attribute_options ||= {}
    end

    def self.memoized(key)
      memoized_attributes[key.to_sym] = Proc.new
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{key}() self[:#{key}]; end
      RUBY
    end

    def self.memoized_attributes
      @memoized_attributes ||= {}
    end

    def self.inherited(subclass)
      super
      subclass.attribute_options.update(attribute_options)
      subclass.memoized_attributes.update(memoized_attributes)
    end

    def self.fetch_error_class
      @fetch_error_class ||= if Object.const_defined?(:KeyError)
                               ::KeyError
                             else
                               ::IndexError
                             end
    end
  end
end

require 'faraday/options/request_options'
require 'faraday/options/ssl_options'
require 'faraday/options/proxy_options'
require 'faraday/options/connection_options'
require 'faraday/options/env'
