# frozen_string_literal: true

module Faraday
  module Utils
    # A case-insensitive Hash that preserves the original case of a header
    # when set.
    #
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
        update(hash || {})
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
        next key if key.respond_to?(:to_str)

        value = key.to_s.split('_') # user_agent: %w(user agent)
                   .each(&:capitalize!) # => %w(User Agent)
                   .join('-') # => "User-Agent"
        keymap_mutex.synchronize { map[key] = value }
      end
      KeyMap[:etag] = 'ETag'

      def [](key)
        key = KeyMap[key]
        super || super(@names[key.downcase])
      end

      def []=(key, val)
        key = KeyMap[key]
        key = (@names[key.downcase] ||= key)
        # join multiple values with a comma
        val = val.to_ary.join(', ') if val.respond_to?(:to_ary)
        super
      end

      alias store []=

      def fetch(key, ...)
        key = KeyMap[key]
        key = @names.fetch(key.downcase, key)
        super
      end

      def delete(key)
        key = KeyMap[key]
        key = @names[key.downcase]
        return unless key

        @names.delete key.downcase
        super
      end

      def clear
        @names.clear
        super
      end

      def shift = rebuilding_names { super }
      def compact! = rebuilding_names { super }
      def rehash = rebuilding_names { super }

      # Without a block these return an enumerator that calls back into the
      # method once iterated, so the index only needs rebuilding in that call.
      def delete_if = block_given? ? rebuilding_names { super } : super
      def keep_if = block_given? ? rebuilding_names { super } : super
      def reject! = block_given? ? rebuilding_names { super } : super
      def select! = block_given? ? rebuilding_names { super } : super
      alias filter! select!

      # A mapping hash is a valid alternative to a block.
      def transform_keys!(*args, &block)
        args.empty? && !block ? super : rebuilding_names { super }
      end

      def dig(key, *rest)
        key = KeyMap[key]
        key = @names.fetch(key.downcase, key)
        super
      end

      def include?(key)
        @names.include? key.downcase
      end

      alias has_key? include?
      alias member? include?
      alias key? include?

      def merge!(other)
        other.each { |k, v| self[k] = v }
        self
      end

      alias update merge!

      def merge(other)
        hash = dup
        hash.merge! other
      end

      def replace(other)
        clear
        @names.clear
        update other
        self
      end

      def to_hash
        {}.update(self)
      end

      def parse(header_string)
        return unless header_string && !header_string.empty?

        headers = header_string.split("\r\n")

        # Find the last set of response headers.
        start_index = headers.rindex { |x| x.start_with?('HTTP/') } || 0
        last_response = headers.slice(start_index, headers.size)

        last_response
          .tap { |a| a.shift if a.first.start_with?('HTTP/') }
          .map { |h| h.split(/:\s*/, 2) } # split key and value
          .reject { |p| p[0].nil? } # ignore blank lines
          .each { |key, value| add_parsed(key, value) }
      end

      protected

      attr_reader :names

      private

      # Runs the block, then rebuilds the name index even if the block raised
      # or exited early, as the underlying Hash may already be partially mutated.
      def rebuilding_names
        yield
      ensure
        rebuild_names
      end

      def rebuild_names
        @names = each_key.to_h { |key| [KeyMap[key].downcase, key] }
      end

      # Join multiple values with a comma.
      def add_parsed(key, value)
        if key?(key)
          self[key] = self[key].to_s
          self[key] << ', ' << value
        else
          self[key] = value
        end
      end
    end
  end
end
