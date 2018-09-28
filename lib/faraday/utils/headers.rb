module Faraday
  module Utils
    # Adapted from Rack::Utils::HeaderHash
    class Headers < ::Hash
      def self.from(value)
        new(value)
      end

      def self.allocate
        new_self = super
        new_self.initialize_names
        new_self
      end

      def initialize(hash = nil)
        super()
        @names = {}
        self.update(hash || {})
      end

      def initialize_names
        @names = {}
      end

      # on dup/clone, we need to duplicate @names hash
      def initialize_copy(other)
        super
        @names = other.names.dup
      end

      # need to synchronize concurrent writes to the shared KeyMap
      keymap_mutex = Mutex.new

      # symbol -> string mapper + cache
      KeyMap = Hash.new do |map, key|
        value = if key.respond_to?(:to_str)
                  key
                else
                  key.to_s.split('_') # :user_agent => %w(user agent)
                    .each { |w| w.capitalize! } # => %w(User Agent)
                    .join('-') # => "User-Agent"
                end
        keymap_mutex.synchronize { map[key] = value }
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
        super(k, v)
      end

      def fetch(k, *args, &block)
        k = KeyMap[k]
        key = @names.fetch(k.downcase, k)
        super(key, *args, &block)
      end

      def delete(k)
        k = KeyMap[k]
        if (k = @names[k.downcase])
          @names.delete k.downcase
          super(k)
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
        @names.clear
        self.update other
        self
      end

      def to_hash
        ::Hash.new.update(self)
      end

      def parse(header_string)
        return unless header_string && !header_string.empty?

        headers = header_string.split(/\r\n/)

        # Find the last set of response headers.
        start_index = headers.rindex { |x| x.match(/^HTTP\//) } || 0
        last_response = headers.slice(start_index, headers.size)

        last_response
          .tap { |a| a.shift if a.first.index('HTTP/') == 0 } # drop the HTTP status line
          .map { |h| h.split(/:\s*/, 2) } # split key and value
          .reject { |p| p[0].nil? } # ignore blank lines
          .each { |key, value| add_parsed(key, value) } # join multiple values with a comma
      end

      protected

      def names
        @names
      end

      private

      def add_parsed(key, value)
        self[key] ? self[key] << ', ' << value : self[key] = value
      end
    end
  end
end
