module Faraday
  # Subclasses Struct with some special helpers for converting from a Hash to
  # a Struct.
  class Options < Struct
    def self.from(value)
      value ? new.update(value) : new
    end

    def self.options(mapping)
      attribute_options.update(mapping)
    end

    def self.options_for(key)
      attribute_options[key]
    end

    def self.attribute_options
      @attribute_options ||= {}
    end

    def each(&block)
      members.each do |key|
        block.call key, send(key)
      end
    end

    def update(obj)
      obj.each do |key, value|
        sub_options = self.class.options_for(key)
        if sub_options && value
          value = sub_options.from(value)
        elsif Hash === value
          hash = {}
          value.each do |hash_key, hash_value|
            hash[hash_key] = hash_value
          end
          value = hash
        end

        self.send("#{key}=", value)
      end
      self
    end

    def merge(value)
      dup.update(value)
    end

    def fetch(key, default = nil)
      send(key) || send("#{key}=", default ||
        (block_given? ? Proc.new.call : nil))
    end

    def values_at(*keys)
      keys.map { |key| send(key) }
    end
  end
end

