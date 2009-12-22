module Faraday
  module AutoloadHelper
    def autoload_all(prefix, options)
      options.each do |const_name, path|
        autoload const_name, File.join(prefix, path)
      end
    end

    # Loads each autoloaded constant.  If thread safety is a concern, wrap
    # this in a Mutex.
    def load
      constants.each do |const|
        const_get(const) if autoload?(const)
      end
    end
  end

  extend AutoloadHelper

  autoload_all 'faraday', 
    :Connection     => 'connection',
    :TestConnection => 'test_connection',
    :Response       => 'response',
    :Error          => 'error'

  module Adapter
    extend AutoloadHelper
    autoload_all 'faraday/adapter', 
      :NetHttp     => 'net_http',
      :Typhoeus    => 'typhoeus',
      :MockRequest => 'mock_request'

    # Names of available adapters.  Should not actually load them.
    def self.adapters
      constants
    end

    # Array of Adapters.  These have been loaded and confirmed to work (right gems, etc).
    def self.loaded_adapters
      adapters.map { |c| const_get(c) }.select { |a| a.loaded? }
    end
  end
end

# not pulling in active-support JUST for this method.
class Object
  # Yields <code>x</code> to the block, and then returns <code>x</code>.
  # The primary purpose of this method is to "tap into" a method chain,
  # in order to perform operations on intermediate results within the chain.
  #
  #   (1..10).tap { |x| puts "original: #{x.inspect}" }.to_a.
  #     tap    { |x| puts "array: #{x.inspect}" }.
  #     select { |x| x%2 == 0 }.
  #     tap    { |x| puts "evens: #{x.inspect}" }.
  #     map    { |x| x*x }.
  #     tap    { |x| puts "squares: #{x.inspect}" }
  def tap
    yield self
    self
  end unless Object.respond_to?(:tap)
end
