module Faraday
  VERSION = "0.8.9"

  class << self
    attr_accessor :root_path, :lib_path
    attr_accessor :default_adapter
    attr_writer   :default_connection

    def new(url = nil, options = {})
      block = block_given? ? Proc.new : nil
      Faraday::Connection.new(url, options, &block)
    end

    def require_libs(*libs)
      libs.each do |lib|
        require "#{lib_path}/#{lib}"
      end
    end

    alias require_lib require_libs

  private
    def method_missing(name, *args, &block)
      default_connection.send(name, *args, &block)
    end
  end

  self.root_path = File.expand_path "..", __FILE__
  self.lib_path = File.expand_path "../faraday", __FILE__
  self.default_adapter = :net_http

  def self.default_connection
    @default_connection ||= Connection.new
  end

  if (!defined?(RUBY_ENGINE) || "ruby" == RUBY_ENGINE) && RUBY_VERSION < '1.9'
    begin
      require 'system_timer'
      Timer = SystemTimer
    rescue LoadError
      warn "Faraday: you may want to install system_timer for reliable timeouts"
    end
  end

  unless const_defined? :Timer
    require 'timeout'
    Timer = Timeout
  end

  module MiddlewareRegistry
    # Internal: Register middleware class(es) on the current module.
    #
    # mapping - A Hash mapping Symbol keys to classes. See
    #           Faraday.register_middleware for more details.
    def register_middleware(mapping)
      (@registered_middleware ||= {}).update(mapping)
    end

    # Internal: Lookup middleware class with a registered Symbol shortcut.
    #
    # Returns a middleware Class.
    def lookup_middleware(key)
      unless defined? @registered_middleware and found = @registered_middleware[key]
        raise "#{key.inspect} is not registered on #{self}"
      end
      found = @registered_middleware[key] = found.call if found.is_a? Proc
      found.is_a?(Module) ? found : const_get(found)
    end
  end

  module AutoloadHelper
    def autoload_all(prefix, options)
      if prefix =~ /^faraday(\/|$)/i
        prefix = File.join(Faraday.root_path, prefix)
      end
      options.each do |const_name, path|
        autoload const_name, File.join(prefix, path)
      end
    end

    # Loads each autoloaded constant.  If thread safety is a concern, wrap
    # this in a Mutex.
    def load_autoloaded_constants
      constants.each do |const|
        const_get(const) if autoload?(const)
      end
    end

    def all_loaded_constants
      constants.map { |c| const_get(c) }.
        select { |a| a.respond_to?(:loaded?) && a.loaded? }
    end
  end

  extend AutoloadHelper

  # Public: register middleware classes under a short name.
  #
  # type    - A Symbol specifying the kind of middleware (default: :middleware)
  # mapping - A Hash mapping Symbol keys to classes. Classes can be expressed
  #           as fully qualified constant, or a Proc that will be lazily called
  #           to return the former.
  #
  # Examples
  #
  #   Faraday.register_middleware :aloha => MyModule::Aloha
  #   Faraday.register_middleware :response, :boom => MyModule::Boom
  #
  #   # shortcuts are now available in Builder:
  #   builder.use :aloha
  #   builder.response :boom
  #
  # Returns nothing.
  def self.register_middleware type, mapping = nil
    type, mapping = :middleware, type if mapping.nil?
    component = self.const_get(type.to_s.capitalize)
    component.register_middleware(mapping)
  end

  autoload_all "faraday",
    :Middleware      => 'middleware',
    :Builder         => 'builder',
    :Request         => 'request',
    :Response        => 'response',
    :CompositeReadIO => 'upload_io',
    :UploadIO        => 'upload_io',
    :Parts           => 'upload_io'

  require_libs "utils", "connection", "adapter", "error"
end


# not pulling in active-support JUST for this method.  And I love this method.
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
