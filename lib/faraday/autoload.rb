module Faraday
  # Adds the ability for other modules to manage autoloadable
  # constants.
  #
  # @api private
  module AutoloadHelper
    # Registers the constants to be auto loaded.
    #
    # @param prefix [String] The require prefix. If the path is inside Faraday, then
    #           it will be prefixed with the root path of this loaded Faraday
    #           version.
    # @param options [{ Symbol => String }] library names.
    #
    # @example
    #
    #   Faraday.autoload_all 'faraday/foo',
    #     :Bar => 'bar'
    #
    #   # requires faraday/foo/bar to load Faraday::Bar.
    #   Faraday::Bar
    #
    #
    # @return [void]
    def autoload_all(prefix, options)
      if prefix =~ /^faraday(\/|$)/i
        prefix = File.join(Faraday.root_path, prefix)
      end
      options.each do |const_name, path|
        autoload const_name, File.join(prefix, path)
      end
    end

    # Loads each autoloaded constant.  If thread safety is a concern,
    # wrap this in a Mutex.
    #
    # @return [void]
    def load_autoloaded_constants
      constants.each do |const|
        const_get(const) if autoload?(const)
      end
    end

    # Filters the module's contents with those that have been already
    # autoloaded.
    #
    # @return [Array<Class, Module>]
    def all_loaded_constants
      constants.map { |c| const_get(c) }.
        select { |a| a.respond_to?(:loaded?) && a.loaded? }
    end
  end

  class Adapter
    extend AutoloadHelper
    autoload_all 'faraday/adapter',
                 :NetHttp => 'net_http',
                 :NetHttpPersistent => 'net_http_persistent',
                 :EMSynchrony => 'em_synchrony',
                 :EMHttp => 'em_http',
                 :Typhoeus => 'typhoeus',
                 :Patron => 'patron',
                 :Excon => 'excon',
                 :Test => 'test',
                 :Rack => 'rack',
                 :HTTPClient => 'httpclient'
  end

  class Request
    extend AutoloadHelper
    autoload_all 'faraday/request',
                 :UrlEncoded => 'url_encoded',
                 :Multipart => 'multipart',
                 :Retry => 'retry',
                 :Authorization => 'authorization',
                 :BasicAuthentication => 'basic_authentication',
                 :TokenAuthentication => 'token_authentication',
                 :Instrumentation => 'instrumentation'
  end

  class Response
    extend AutoloadHelper
    autoload_all 'faraday/response',
                 :RaiseError => 'raise_error',
                 :Logger => 'logger'
  end
end
