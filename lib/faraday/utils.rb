require 'cgi'

module Faraday
  module Utils
    extend self

    # Adapted from Rack::Utils::HeaderHash
    class Headers < ::Hash
      def initialize(hash={})
        super()
        @names = {}
        self.update hash
      end

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
        k = KeyMap[k]
        super(k) || super(@names[k.downcase])
      end

      def []=(k, v)
        k = KeyMap[k]
        k = (@names[k.downcase] ||= k)
        # join multiple values with a comma
        v = v.to_ary.join(', ') if v.respond_to? :to_ary
        super k, v
      end

      def delete(k)
        k = KeyMap[k]
        if k = @names[k.downcase]
          @names.delete k.downcase
          super k
        end
      end

      def include?(k)
        @names.include? k.downcase
      end

      alias_method :has_key?, :include?
      alias_method :member?, :include?
      alias_method :key?, :include?

      def merge!(other)
        other.each { |k, v| self[k] = v }
        self
      end
      alias_method :update, :merge!

      def merge(other)
        hash = dup
        hash.merge! other
      end

      def replace(other)
        clear
        self.update other
        self
      end

      def to_hash() ::Hash.new.update(self) end

      def parse(header_string)
        return unless header_string && !header_string.empty?
        header_string.split(/\r\n/).
          tap  { |a| a.shift if a.first.index('HTTP/') == 0 }. # drop the HTTP status line
          map  { |h| h.split(/:\s+/, 2) }.reject { |p| p[0].nil? }. # split key and value, ignore blank lines
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
          update Utils.parse_nested_query(query)
        end
        self
      end

      def to_query
        Utils.build_nested_query(self)
      end

      private

      def convert_key(key)
        key.to_s
      end
    end

    # Copied from Rack
    def build_query(params)
      params.map { |k, v|
        if v.class == Array
          build_query(v.map { |x| [k, x] })
        else
          v.nil? ? escape(k) : "#{escape(k)}=#{escape(v)}"
        end
      }.join("&")
    end

    # Rack's version modified to handle non-String values
    def build_nested_query(value, prefix = nil)
      case value
      when Array
        value.map { |v| build_nested_query(v, "#{prefix}%5B%5D") }.join("&")
      when Hash
        value.map { |k, v|
          build_nested_query(v, prefix ? "#{prefix}%5B#{escape(k)}%5D" : escape(k))
        }.join("&")
      when NilClass
        prefix
      else
        raise ArgumentError, "value must be a Hash" if prefix.nil?
        "#{prefix}=#{escape(value)}"
      end
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
    def parse_query(qs)
      params = {}

      (qs || '').split(DEFAULT_SEP).each do |p|
        k, v = p.split('=', 2).map { |x| unescape(x) }

        if cur = params[k]
          if cur.class == Array then params[k] << v
          else params[k] = [cur, v]
          end
        else
          params[k] = v
        end
      end
      params
    end

    def parse_nested_query(qs)
      params = {}

      (qs || '').split(DEFAULT_SEP).each do |p|
        k, v = p.split('=', 2).map { |s| unescape(s) }
        normalize_params(params, k, v)
      end
      params
    end

    # Stolen from Rack
    def normalize_params(params, name, v = nil)
      name =~ %r(\A[\[\]]*([^\[\]]+)\]*)
      k = $1 || ''
      after = $' || ''

      return if k.empty?

      if after == ""
        params[k] = v
      elsif after == "[]"
        params[k] ||= []
        raise TypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
        params[k] << v
      elsif after =~ %r(^\[\]\[([^\[\]]+)\]$) || after =~ %r(^\[\](.+)$)
        child_key = $1
        params[k] ||= []
        raise TypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
        if params[k].last.is_a?(Hash) && !params[k].last.key?(child_key)
          normalize_params(params[k].last, child_key, v)
        else
          params[k] << normalize_params({}, child_key, v)
        end
      else
        params[k] ||= {}
        raise TypeError, "expected Hash (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Hash)
        params[k] = normalize_params(params[k], after, v)
      end

      return params
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
