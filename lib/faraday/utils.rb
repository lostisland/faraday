require 'rack/utils'

module Faraday
  module Utils
    include Rack::Utils

    extend Rack::Utils
    extend self

    class Headers < HeaderHash
      # symbol -> string mapper + cache
      KeyMap = Hash.new do |map, key|
        map[key] = if key.respond_to?(:to_str) then key
        else
          key.to_s.split('_').            # :user_agent => %w(user agent)
            each { |w| w.capitalize! }.   # => %w(User Agent)
            join('-')                     # => "User-Agent"
        end
      end
      KeyMap[:etag] = "ETag"

      def [](k)
        super(KeyMap[k])
      end

      def []=(k, v)
        # join multiple values with a comma
        v = v.to_ary.join(', ') if v.respond_to? :to_ary
        super(KeyMap[k], v)
      end

      alias_method :update, :merge!

      def parse(header_string)
        return unless header_string && !header_string.empty?
        header_string.split(/\r\n/).
          tap  { |a| a.shift if a.first.index('HTTP/') == 0 }. # drop the HTTP status line
          map  { |h| h.split(/:\s+/, 2) }.reject { |(k, v)| k.nil? }. # split key and value, ignore blank lines
          each { |key, value|
            # join multiple values with a comma
            if self[key] then self[key] << ', ' << value
            else self[key] = value
            end
          }
      end
    end

    # hash with stringified keys
    class ParamsHash < Hash
      def [](key)
        super(convert_key(key))
      end

      def []=(key, value)
        super(convert_key(key), value)
      end

      def delete(key)
        super(convert_key(key))
      end

      def include?(key)
        super(convert_key(key))
      end

      alias_method :has_key?, :include?
      alias_method :member?, :include?
      alias_method :key?, :include?

      def update(params)
        params.each do |key, value|
          self[key] = value
        end
        self
      end
      alias_method :merge!, :update

      def merge(params)
        dup.update(params)
      end

      def replace(other)
        clear
        update(other)
      end

      def merge_query(query)
        if query && !query.empty?
          update Utils.parse_query(query)
        end
        self
      end

      def to_query
        Utils.build_query(self)
      end

      private

      def convert_key(key)
        key.to_s
      end
    end

    # Make Rack::Utils methods public.
    public :build_query, :parse_query

    # Override Rack's version since it doesn't handle non-String values
    def build_nested_query(value, prefix = nil)
      case value
      when Array
        value.map { |v| build_nested_query(v, "#{prefix}[]") }.join("&")
      when Hash
        value.map { |k, v|
          build_nested_query(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
        }.join("&")
      when NilClass
        prefix
      else
        raise ArgumentError, "value must be a Hash" if prefix.nil?
        "#{prefix}=#{escape(value)}"
      end
    end

    # Be sure to URI escape '+' symbols to %2B. Otherwise, they get interpreted
    # as spaces.
    def escape(s)
      s.to_s.gsub(/([^a-zA-Z0-9_.-]+)/n) do
        '%' << $1.unpack('H2'*bytesize($1)).join('%').tap { |c| c.upcase! }
      end
    end

    # Receives a URL and returns just the path with the query string sorted.
    def normalize_path(url)
      (url.path != "" ? url.path : "/") +
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
