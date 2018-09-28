require 'thread'

require_relative 'utils/headers'
require_relative 'utils/params_hash'

module Faraday
  module Utils
    extend self

    def build_query(params)
      FlatParamsEncoder.encode(params)
    end

    def build_nested_query(params)
      NestedParamsEncoder.encode(params)
    end

    ESCAPE_RE = /[^a-zA-Z0-9 .~_-]/

    def escape(s)
      s.to_s.gsub(ESCAPE_RE) {|match|
        '%' + match.unpack('H2' * match.bytesize).join('%').upcase
      }.tr(' ', '+')
    end

    def unescape(s) CGI.unescape s.to_s end

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

    class << self
      attr_writer :default_params_encoder
    end

    # # Stolen from Rack
    # def normalize_params(params, name, v = nil)
    #   name =~ %r(\A[\[\]]*([^\[\]]+)\]*)
    #   k = $1 || ''
    #   after = $' || ''
    #
    #   return if k.empty?
    #
    #   if after == ""
    #     if params[k]
    #       params[k] = Array[params[k]] unless params[k].kind_of?(Array)
    #       params[k] << v
    #     else
    #       params[k] = v
    #     end
    #   elsif after == "[]"
    #     params[k] ||= []
    #     raise TypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
    #     params[k] << v
    #   elsif after =~ %r(^\[\]\[([^\[\]]+)\]$) || after =~ %r(^\[\](.+)$)
    #     child_key = $1
    #     params[k] ||= []
    #     raise TypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
    #     if params[k].last.is_a?(Hash) && !params[k].last.key?(child_key)
    #       normalize_params(params[k].last, child_key, v)
    #     else
    #       params[k] << normalize_params({}, child_key, v)
    #     end
    #   else
    #     params[k] ||= {}
    #     raise TypeError, "expected Hash (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Hash)
    #     params[k] = normalize_params(params[k], after, v)
    #   end
    #
    #   return params
    # end

    # Normalize URI() behavior across Ruby versions
    #
    # url - A String or URI.
    #
    # Returns a parsed URI.
    def URI(url)
      if url.respond_to?(:host)
        url
      elsif url.respond_to?(:to_str)
        default_uri_parser.call(url)
      else
        raise ArgumentError, "bad argument (expected URI object or URI string)"
      end
    end

    def default_uri_parser
      @default_uri_parser ||= begin
        require 'uri'
        Kernel.method(:URI)
      end
    end

    def default_uri_parser=(parser)
      @default_uri_parser = if parser.respond_to?(:call) || parser.nil?
        parser
      else
        parser.method(:parse)
      end
    end

    # Receives a String or URI and returns just the path with the query string sorted.
    def normalize_path(url)
      url = URI(url)
      (url.path.start_with?('/') ? url.path : '/' + url.path) +
      (url.query ? "?#{sort_query_params(url.query)}" : "")
    end

    # Recursive hash update
    def deep_merge!(target, hash)
      hash.each do |key, value|
        if Hash === value and Hash === target[key]
          target[key] = deep_merge(target[key], value)
        else
          target[key] = value
        end
      end
      target
    end

    # Recursive hash merge
    def deep_merge(source, hash)
      deep_merge!(source.dup, hash)
    end

    protected

    def sort_query_params(query)
      query.split('&').sort.join('&')
    end
  end
end
