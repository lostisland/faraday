# frozen_string_literal: true

module Faraday
  # Marker module for Options-like objects.
  #
  # It is included by the legacy {Options} (a Struct) and by {BaseOptions}, so
  # code can treat both uniformly, e.g. {Utils.deep_merge!} and {Utils.deep_dup}
  # recurse into any OptionsLike value. Including classes are expected to
  # respond to +to_hash+ and +deep_dup+.
  #
  # Utils deep merges objects that include this module with +[]+, +[]=+ and +dup+
  # (like {Options}), or that inherit from {BaseOptions}.
  #
  # @see BaseOptions
  # @see Options
  module OptionsLike
  end
end
