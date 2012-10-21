module Faraday
  # Subclasses Struct with some special helpers for converting from a Hash to
  # a Struct.
  class Options < Struct
    def self.from(value)
      value ? new.update(value) : new
    end

    def each(&block)
      members.each do |key|
        block.call key, send(key)
      end
    end

    def update(value)
      value.each do |key, value|
        if Hash === value
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
  end
end

