# frozen_string_literal: true

module Faraday
  # Marker module for Options-like objects.
  #
  # This module enables duck-typed interoperability between legacy {Options}
  # and new {BaseOptions} classes. It provides a stable interface for:
  # - Integration with {Utils.deep_merge!}
  # - Type checking in option coercion logic
  # - Uniform handling of option objects across the codebase
  #
  # @example Including in custom options classes
  #   class MyOptions
  #     include Faraday::OptionsLike
  #
  #     def to_hash
  #       { key: value }
  #     end
  #   end
  #
  # @see BaseOptions
  # @see Options
  module OptionsLike
  end
end
