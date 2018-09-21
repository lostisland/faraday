require 'thread'
require 'cgi'
require 'set'
require 'forwardable'

# This is the main namespace for Faraday.
#
# It provides methods to create {Connection} objects, and HTTP-related
# methods to use directly.
#
# @example Helpful class methods for easy usage
#   Faraday.get "http://faraday.com"
#
# @example Helpful class method `.new` to create {Connection} objects.
#   conn = Faraday.new "http://faraday.com"
#   conn.get '/'
#
module Faraday
  VERSION = "0.15.3"

  class << self
    # The root path that Faraday is being loaded from.
    #
    # This is the root from where the libraries are auto-loaded.
    #
    # @return [String]
    attr_accessor :root_path

    # Gets or sets the path that the Faraday libs are loaded from.
    # @return [String]
    attr_accessor :lib_path

    # @overload default_adapter
    #   Gets the Symbol key identifying a default Adapter to use
    #   for the default {Faraday::Connection}. Defaults to `:net_http`.
    #   @return [Symbol] the default adapter
    # @overload default_adapter=(adapter)
    #   Updates default adapter while resetting {.default_connection}.
    #   @return [Symbol] the new default_adapter.
    attr_reader :default_adapter

    # Documented below, see default_connection
    attr_writer :default_connection

    # Tells Faraday to ignore the environment proxy (http_proxy). Defaults to `false`.
    # @return [Boolean]
    attr_accessor :ignore_env_proxy

    # Initializes a new {Connection}.
    #
    # @param url [String,Hash] The optional String base URL to use as a prefix for all
    #           requests.  Can also be the options Hash. Any of these values
    #           will be set on every request made, unless overridden for a
    #           specific request.
    # @param options [Hash]
    # @option options [String] :url Base URL
    # @option options [Hash] :params Hash of URI query unencoded key/value pairs.
    # @option options [Hash] :headers Hash of unencoded HTTP header key/value pairs.
    # @option options [Hash] :request Hash of request options.
    # @option options [Hash] :ssl Hash of SSL options.
    # @option options [Hash] :proxy Hash of Proxy options.
    # @return [Faraday::Connection]
    #
    # @example With an URL argument
    #   Faraday.new 'http://faraday.com'
    #   # => Faraday::Connection to http://faraday.com
    #   
    # @example With an URL argument and an options hash
    #   Faraday.new 'http://faraday.com', :params => {:page => 1}
    #   # => Faraday::Connection to http://faraday.com?page=1
    #
    # @example With everything in an options hash
    #   Faraday.new :url => 'http://faraday.com',
    #               :params => {:page => 1}
    #   # => Faraday::Connection to http://faraday.com?page=1
    def new(url = nil, options = nil)
      block = block_given? ? Proc.new : nil
      options = options ? default_connection_options.merge(options) : default_connection_options
      Faraday::Connection.new(url, options, &block)
    end

    # @private
    # Internal: Requires internal Faraday libraries.
    #
    # @param libs [Array] one or more relative String names to Faraday classes.
    # @return [void]
    def require_libs(*libs)
      libs.each do |lib|
        require "#{lib_path}/#{lib}"
      end
    end

    alias require_lib require_libs

    # Documented elsewhere, see default_adapter reader
    def default_adapter=(adapter)
      @default_connection = nil
      @default_adapter = adapter
    end

    def respond_to?(symbol, include_private = false)
      default_connection.respond_to?(symbol, include_private) || super
    end

  private
    # Internal: Proxies method calls on the Faraday constant to
    # .default_connection.
    def method_missing(name, *args, &block)
      default_connection.send(name, *args, &block)
    end
  end

  self.ignore_env_proxy = false
  self.root_path = File.expand_path "..", __FILE__
  self.lib_path = File.expand_path "../faraday", __FILE__
  self.default_adapter = :net_http

  # @overload default_connection
  #   Gets the default connection used for simple scripts.
  #   @return [Faraday::Connection] a connection configured with the {.default_adapter}.
  # @overload default_connection=(connection)
  #   @param connection [Faraday::Connection]
  #   Sets the default {Faraday::Connection} for simple scripts that
  #   access the Faraday constant directly, such as <code>Faraday.get "https://faraday.com"</code>.
  def self.default_connection
    @default_connection ||= Connection.new(default_connection_options)
  end

  # Gets the default connection options used when calling {Faraday#new}.
  #
  # @return [Faraday::ConnectionOptions]
  def self.default_connection_options
    @default_connection_options ||= ConnectionOptions.new
  end

  # Sets the default options used when calling {Faraday#new}.
  #
  # @param options [Hash, Faraday::ConnectionOptions]
  def self.default_connection_options=(options)
    @default_connection = nil
    @default_connection_options = ConnectionOptions.from(options)
  end

  unless const_defined? :Timer
    require 'timeout'
    Timer = Timeout
  end

  # Adds the ability for other modules to register and lookup
  # middleware classes.
  module MiddlewareRegistry
    # Register middleware class(es) on the current module.
    #
    # @param autoload_path [String] Middleware autoload path
    # @param mapping [Hash{Symbol => Module, Symbol, Array<Module, Symbol, String>}] Middleware mapping from a lookup symbol to a reference to the middleware. - Classes can be expressed as:
    #           - a fully qualified constant
    #           - a Symbol
    #           - a Proc that will be lazily called to return the former
    #           - an array is given, its first element is the constant or symbol,
    #             and its second is a file to `require`.
    # @return [void]
    #
    # @example Lookup by a constant
    #
    #   module Faraday
    #     class Whatever
    #       # Middleware looked up by :foo returns Faraday::Whatever::Foo.
    #       register_middleware :foo => Foo
    #     end
    #   end
    #
    # @example Lookup by a symbol
    #
    #   module Faraday
    #     class Whatever
    #       # Middleware looked up by :bar returns Faraday::Whatever.const_get(:Bar)
    #       register_middleware :bar => :Bar
    #     end
    #   end
    #
    # @example Lookup by a symbol and string in an array
    #
    #   module Faraday
    #     class Whatever
    #       # Middleware looked up by :baz requires 'baz' and returns Faraday::Whatever.const_get(:Baz)
    #       register_middleware :baz => [:Baz, 'baz']
    #     end
    #   end
    #       
    def register_middleware(autoload_path = nil, mapping = nil)
      if mapping.nil?
        mapping = autoload_path
        autoload_path = nil
      end
      middleware_mutex do
        @middleware_autoload_path = autoload_path if autoload_path
        (@registered_middleware ||= {}).update(mapping)
      end
    end

    # Lookup middleware class with a registered Symbol shortcut.
    #
    # @param key [Symbol] key for the registered middleware.
    # @return [Class] a middleware Class.
    # @raise [Faraday::Error] if given key is not registered
    #
    # @example
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
    def lookup_middleware(key)
      load_middleware(key) ||
        raise(Faraday::Error.new("#{key.inspect} is not registered on #{self}"))
    end

    def middleware_mutex(&block)
      @middleware_mutex ||= begin
        require 'monitor'
        Monitor.new
      end
      @middleware_mutex.synchronize(&block)
    end

    def fetch_middleware(key)
      defined?(@registered_middleware) && @registered_middleware[key]
    end

    def load_middleware(key)
      value = fetch_middleware(key)
      case value
      when Module
        value
      when Symbol, String
        middleware_mutex do
          @registered_middleware[key] = const_get(value)
        end
      when Proc
        middleware_mutex do
          @registered_middleware[key] = value.call
        end
      when Array
        middleware_mutex do
          const, path = value
          if root = @middleware_autoload_path
            path = "#{root}/#{path}"
          end
          require(path)
          @registered_middleware[key] = const
        end
        load_middleware(key)
      end
    end
  end

  # @private
  def self.const_missing(name)
    if name.to_sym == :Builder
      warn "Faraday::Builder is now Faraday::RackBuilder."
      const_set name, RackBuilder
    else
      super
    end
  end

  require_libs "utils", "options", "connection", "rack_builder", "parameters",
    "middleware", "adapter", "request", "response", "upload_io", "error"

  if !ENV["FARADAY_NO_AUTOLOAD"]
    require_lib 'autoload'
  end
end
