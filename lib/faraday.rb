# frozen_string_literal: true

require 'cgi'
require 'set'
require 'forwardable'
require 'faraday/middleware_registry'
require 'faraday/dependency_loader'

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
  VERSION = '0.15.3'
  METHODS_WITH_QUERY = %w[get head delete connect trace].freeze
  METHODS_WITH_BODY = %w[post put patch].freeze
  AGENT_ALIASES = {
    'Faraday' => "Faraday v#{VERSION}",
    'Linux Firefox' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0',
    'Linux Konqueror' => 'Mozilla/5.0 (compatible; Konqueror/3; Linux)',
    'Linux Mozilla' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
    'Mac Firefox' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:43.0) Gecko/20100101 Firefox/43.0',
    'Mac Mozilla' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
    'Mac Safari 4' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; de-at) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10',
    'Mac Safari' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9',
    'Windows Chrome' => 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.125 Safari/537.36',
    'Windows IE 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
    'Windows IE 7' => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',
    'Windows IE 8' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',
    'Windows IE 9' => 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)',
    'Windows IE 10' => 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; WOW64; Trident/6.0)',
    'Windows IE 11' => 'Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; rv:11.0) like Gecko',
    'Windows Edge' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2486.0 Safari/537.36 Edge/13.10586',
    'Windows Mozilla' => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
    'Windows Firefox' => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:43.0) Gecko/20100101 Firefox/43.0',
    'iPhone' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B5110e Safari/601.1',
    'iPad' => 'Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1',
    'Android' => 'Mozilla/5.0 (Linux; Android 5.1.1; Nexus 7 Build/LMY47V) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.76 Safari/537.36',
  }.freeze

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

    # Tells Faraday to ignore the environment proxy (http_proxy).
    # Defaults to `false`.
    # @return [Boolean]
    attr_accessor :ignore_env_proxy

    # Initializes a new {Connection}.
    #
    # @param url [String,Hash] The optional String base URL to use as a prefix
    #           for all requests.  Can also be the options Hash. Any of these
    #           values will be set on every request made, unless overridden
    #           for a specific request.
    # @param options [Hash]
    # @option options [String] :url Base URL
    # @option options [Hash] :params Hash of unencoded URI query params.
    # @option options [Hash] :headers Hash of unencoded HTTP headers.
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
    #   Faraday.new 'http://faraday.com', params: { page: 1 }
    #   # => Faraday::Connection to http://faraday.com?page=1
    #
    # @example With everything in an options hash
    #   Faraday.new url: 'http://faraday.com',
    #               params: { page: 1 }
    #   # => Faraday::Connection to http://faraday.com?page=1
    def new(url = nil, options = {}, &block)
      options = default_connection_options.merge(options)
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

    def respond_to_missing?(symbol, include_private = false)
      default_connection.respond_to?(symbol, include_private) || super
    end

    private

    # Internal: Proxies method calls on the Faraday constant to
    # .default_connection.
    def method_missing(name, *args, &block)
      if default_connection.respond_to?(name)
        default_connection.send(name, *args, &block)
      else
        super
      end
    end
  end

  self.ignore_env_proxy = false
  self.root_path = File.expand_path __dir__
  self.lib_path = File.expand_path 'faraday', __dir__
  self.default_adapter = :net_http

  # @overload default_connection
  #   Gets the default connection used for simple scripts.
  #   @return [Faraday::Connection] a connection configured with
  #   the default_adapter.
  # @overload default_connection=(connection)
  #   @param connection [Faraday::Connection]
  #   Sets the default {Faraday::Connection} for simple scripts that
  #   access the Faraday constant directly, such as
  #   <code>Faraday.get "https://faraday.com"</code>.
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

  require_libs 'utils', 'options', 'connection', 'rack_builder', 'parameters',
               'middleware', 'adapter', 'request', 'response', 'upload_io',
               'error'

  require_lib 'autoload' unless ENV['FARADAY_NO_AUTOLOAD']
end
