# frozen_string_literal: true

module Faraday
  # Allows for the deprecation of constants between versions of Faraday
  #
  # rubocop:disable Style/MethodMissingSuper, Style/MissingRespondToMissing
  class DeprecatedConstant < Module
    def self.new(*args, &block)
      object = args.first
      return object unless object

      super
    end

    def initialize(old_const, new_const)
      @old_const = old_const
      @new_const = new_const
    end

    # TODO: use match? once Faraday drops Ruby 2.3 support
    instance_methods.each do |method_name|
      undef_method method_name if /^__|^object_id$/.match(method_name).nil?
    end

    def inspect
      @new_const.inspect
    end

    def class
      @new_const.class
    end

    private

    def const_missing(name)
      warn
      @new_const.const_get(name)
    end

    def method_missing(method_name, *args, &block)
      warn
      @new_const.__send__(method_name, *args, &block)
    end

    def warn
      puts(
        "DEPRECATION WARNING: #{@old_const} is deprecated! " \
        "Use #{@new_const} instead."
      )
    end
  end
  # rubocop:enable Style/MethodMissingSuper, Style/MissingRespondToMissing
end
