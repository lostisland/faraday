# frozen_string_literal: true

require 'uri'
require 'faraday/utils/headers'
require 'faraday/utils/params_hash'

module Faraday
  # Utils contains various static helper methods.
  module Utils
    module_function

    def build_query(params)
      FlatParamsEncoder.encode(params)
    end

    def build_nested_query(params)
      NestedParamsEncoder.encode(params)
    end

    def default_space_encoding
      @default_space_encoding ||= '+'
    end

    class << self
      attr_writer :default_space_encoding
    end

    ESCAPE_RE = /[^a-zA-Z0-9 .~_-]/

    # CGI.escape works on raw bytes: it matches ESCAPE_RE only where no multibyte character
    # hides an ASCII byte (Shift_JIS 'ア' is "\x83A"), unlike ESCAPE_RE it doesn't raise on
    # invalid bytes, and it returns String subclasses (SafeBuffer) as is when nothing is escaped.
    CGI_ESCAPE_ENCODINGS = [Encoding::UTF_8, Encoding::US_ASCII, Encoding::BINARY].freeze
    private_constant :CGI_ESCAPE_ENCODINGS

    def escape(str)
      str = str.to_s
      if str.instance_of?(String) && CGI_ESCAPE_ENCODINGS.include?(str.encoding) && str.valid_encoding?
        escaped = CGI.escape(str)
        default_space_encoding == '+' ? escaped : escaped.gsub('+', default_space_encoding)
      else
        str.gsub(ESCAPE_RE) do |match|
          "%#{match.unpack('H2' * match.bytesize).join('%').upcase}"
        end.gsub(' ', default_space_encoding)
      end
    end

    def unescape(str)
      CGI.unescape str.to_s
    end

    DEFAULT_SEP = /[&;] */n

    # Adapted from Rack
    def parse_query(query)
      FlatParamsEncoder.decode(query)
    end

    def parse_nested_query(query)
      NestedParamsEncoder.decode(query)
    end

    def default_params_encoder
      @default_params_encoder ||= NestedParamsEncoder
    end

    def basic_header_from(login, pass)
      value = ["#{login}:#{pass}"].pack('m') # Base64 encoding
      value.delete!("\n")
      "Basic #{value}"
    end

    class << self
      attr_writer :default_params_encoder
    end

    # Normalize URI() behavior across Ruby versions
    #
    # url - A String or URI.
    #
    # Returns a parsed URI.
    def URI(url) # rubocop:disable Naming/MethodName
      if url.respond_to?(:host)
        url
      elsif url.respond_to?(:to_str)
        default_uri_parser.call(url)
      else
        raise ArgumentError, 'bad argument (expected URI object or URI string)'
      end
    end

    def default_uri_parser
      @default_uri_parser ||= Kernel.method(:URI)
    end

    def default_uri_parser=(parser)
      @default_uri_parser = if parser.respond_to?(:call) || parser.nil?
                              parser
                            else
                              parser.method(:parse)
                            end
    end

    # Receives a String or URI and returns just
    # the path with the query string sorted.
    def normalize_path(url)
      url = URI(url)
      (url.path.start_with?('/') ? url.path : "/#{url.path}") +
        (url.query ? "?#{sort_query_params(url.query)}" : '')
    end

    # Recursive hash update
    #
    # Hash and {OptionsLike} values of +target+ are merged with Hash values of
    # +hash+, anything else is replaced. A {BaseOptions} target merges itself,
    # unless it includes {StructCompat}: like the legacy {Options}, it is
    # updated key by key, so +nil+ values are written too.
    #
    # @param target [Hash, Options, BaseOptions] the object to update
    # @param hash [Hash] the values to merge in
    # @return [Hash, Options, BaseOptions] +target+
    def deep_merge!(target, hash)
      return target.merge!(hash) if target.is_a?(BaseOptions) && !target.is_a?(StructCompat)

      hash.each do |key, value|
        target_value = target[key]
        mergeable = value.is_a?(Hash) && (target_value.is_a?(Hash) || target_value.is_a?(OptionsLike))
        target[key] = mergeable ? deep_merge(target_value, value) : value
      end
      target
    end

    # Deep duplication of values
    #
    # Hashes, Arrays and {OptionsLike} objects are duplicated recursively, any
    # other object is returned as it is.
    #
    # @param value [Object] the value to duplicate
    # @return [Object] a deep copy of the value
    def deep_dup(value)
      case value
      when Hash
        value.dup.transform_values! { |v| deep_dup(v) }
      when Array
        value.map { |v| deep_dup(v) }
      when OptionsLike
        value.deep_dup
      else
        value
      end
    end

    # Recursive hash merge, see {deep_merge!}. Does not modify +source+.
    #
    # A {BaseOptions} +source+ is deeply duplicated, so the result shares no
    # nested objects with it. Other sources are duplicated shallowly.
    def deep_merge(source, hash)
      source.is_a?(BaseOptions) && !source.is_a?(StructCompat) ? source.merge(hash) : deep_merge!(source.dup, hash)
    end

    def sort_query_params(query)
      query.split('&').sort.join('&')
    end
  end
end
