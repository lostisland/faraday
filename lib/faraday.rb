# Public: This is the main namespace for Faraday.  You can either use it to
# create Faraday::Connection objects, or access it directly.
#
# Examples
#
#   Faraday.get "http://faraday.com"
#
#   conn = Faraday.new "http://faraday.com"
#   conn.get '/'
#
module Faraday
  VERSION = "0.8.0"

  class << self
    # Public: Gets or sets the root path that Faraday is being loaded from.
    # This is the root from where the libraries are auto-loaded from.
    attr_accessor :root_path

    # Public: Gets or sets the path that the Faraday libs are loaded from.
    attr_accessor :lib_path

    # Public: Gets or sets the Symbol key identifying a default Adapter to use
    # for the default Faraday::Connection.
    attr_accessor :default_adapter

    # Public: Sets the default Faraday::Connection for simple scripts that
    # access the Faraday constant directly.
    #
    #     Faraday.get "https://faraday.com"
    attr_writer :default_connection

    # Public: Initializes a new Faraday::Collection.
    #
    # url     - The optional String base URL to use as a prefix for all
    #           requests.  Can also be the options Hash.
    # options - The optional Hash used to configure this Faraday::Connection.
    #           Any of these values will be set on every request made, unless
    #           overridden for a specific request.
    #           :url     - String base URL.
    #           :params  - Hash of URI query unencoded key/value pairs.
    #           :headers - Hash of unencoded HTTP header key/value pairs.
    #           :request - Hash of request options.
    #           :ssl     - Hash of SSL options.
    #           :proxy   - Hash of Proxy options.
    #
    # Examples
    #
    #   Faraday.new 'http://faraday.com'
    #
    #   # http://faraday.com?page=1
    #   Faraday.new 'http://faraday.com', :params => {:page => 1}
    #
    #   # same
    #
    #   Faraday.new :url => 'http://faraday.com',
    #     :params => {:page => 1}
    #
    # Returns a Faraday::Connection.
    def new(url = nil, options = {})
      block = block_given? ? Proc.new : nil
      Faraday::Connection.new(url, options, &block)
    end

    # Internal: Requires internal Faraday libraries.
    #
    # *libs - One or more relative String names to Faraday classes.
    #
    # Returns nothing.
    def require_libs(*libs)
      libs.each do |lib|
        require "#{lib_path}/#{lib}"
      end
    end

    alias require_lib require_libs

  private
    # Internal: Proxies method calls on the Faraday constant to
    # #default_connection.
    def method_missing(name, *args, &block)
      default_connection.send(name, *args, &block)
    end
  end

  self.root_path = File.expand_path "..", __FILE__
  self.lib_path = File.expand_path "../faraday", __FILE__
  self.default_adapter = :net_http

  # Gets the default connection used for simple scripts.
  #
  # Returns a Faraday::Connection, configured with the #default_adapter.
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

  # Public: Adds the ability for other modules to register and lookup
  # middleware classes.
  module MiddlewareRegistry
    # Public: Register middleware class(es) on the current module.
    #
    # mapping - A Hash mapping Symbol keys to classes. Classes can be expressed
    #           as fully qualified constant, or a Proc that will be lazily
    #           called to return the former.
    #
    # Examples
    #
    #   module Faraday
    #     class Whatever
    #       # Middleware looked up by :foo returns Faraday::Whatever::Foo.
    #       register_middleware :foo => Foo
    #     end
    #   end
    #
    # Returns nothing.
    def register_middleware(mapping)
      (@registered_middleware ||= {}).update(mapping)
    end

    # Public: Lookup middleware class with a registered Symbol shortcut.
    #
    # key - The Symbol key for the registered middleware.
    #
    # Examples
    #
    #   module Faraday
    #     class Whatever
    #       register_middleware :foo => Foo
    #     end
    #   end
    #
    #   Faraday::Whatever.lookup_middleware(:foo)
    #   # => Faraday::Whatever::Foo
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

  # Internal: Adds the ability for other modules to manage autoloadable
  # constants.
  module AutoloadHelper
    # Internal: Registers the constants to be auto loaded.
    #
    # prefix  - The String require prefix.  If the path is inside Faraday, then
    #           it will be prefixed with the root path of this loaded Faraday
    #           version.
    # options - Hash of Symbol => String library names.
    #
    # Examples.
    #
    #   Faraday.autoload_all 'faraday/foo',
    #     :Bar => 'bar'
    #
    #   # requires faraday/foo/bar to load Faraday::Bar.
    #   Faraday::Bar
    #
    #
    # Returns nothing.
    def autoload_all(prefix, options)
      if prefix =~ /^faraday(\/|$)/i
        prefix = File.join(Faraday.root_path, prefix)
      end
      options.each do |const_name, path|
        autoload const_name, File.join(prefix, path)
      end
    end

    # Internal: Loads each autoloaded constant.  If thread safety is a concern,
    # wrap this in a Mutex.
    #
    # Returns nothing.
    def load_autoloaded_constants
      constants.each do |const|
        const_get(const) if autoload?(const)
      end
    end

    # Internal: Filters the module's contents with those that have been already
    # autoloaded.
    #
    # Returns an Array of Class/Module objects.
    def all_loaded_constants
      constants.map { |c| const_get(c) }.
        select { |a| a.respond_to?(:loaded?) && a.loaded? }
    end
  end

  extend AutoloadHelper

  # Public: Register middleware classes under a short name.
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
  def self.register_middleware(type, mapping = nil)
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
  # The primary purpose of this method is to "tap into" a method chain,
  # in order to perform operations on intermediate results within the chain.
  #
  # Examples
  #
  #   (1..10).tap { |x| puts "original: #{x.inspect}" }.to_a.
  #     tap    { |x| puts "array: #{x.inspect}" }.
  #     select { |x| x%2 == 0 }.
  #     tap    { |x| puts "evens: #{x.inspect}" }.
  #     map    { |x| x*x }.
  #     tap    { |x| puts "squares: #{x.inspect}" }
  #
  # Yields self.
  # Returns self.
  def tap
    yield self
    self
  end unless Object.respond_to?(:tap)
end
