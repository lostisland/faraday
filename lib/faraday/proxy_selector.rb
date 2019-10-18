# frozen_string_literal: true

# Faraday module.
module Faraday
  # Builds a ProxySelector that uses the given env. If no env is provided,
  # this defaults to ENV unless Faraday.ignore_env_proxy is enabled.
  #
  # @param env [Hash, nil] Hash of environment variables, which can be set with
  #        Symbol, String, or uppercased String keys.
  #        Ex: :http_proxy, 'http_proxy', or 'HTTP_PROXY'
  # @option env [String] :http_proxy Used as the proxy for HTTP and HTTPS
  #         requests, unless overridden by :https_proxy or :no_proxy
  # @option env [String] :https_proxy Used as the proxy for HTTPS requests,
  #         unless overridden by :no_proxy
  # @option env [String] :no_proxy A String that contains comma-separated values
  #         specifying hosts that should be excluded from proxying. Each value
  #         is represented by an IP address prefix (1.2.3.4), an IP address
  #         prefix in CIDR notation (1.2.3.4/8), a domain name, or a special DNS
  #         label (*). An IP address prefix and domain name can also include a
  #         literal port number (1.2.3.4:80).
  #         A domain name matches that name and all subdomains. A domain name
  #         with a leading "." matches subdomains only. For example "foo.com"
  #         matches "foo.com" and "bar.foo.com"; ".y.com" matches "x.y.com" but
  #         not "y.com". A single asterisk (*) indicates that no proxying should
  #         be done. A best effort is made to parse the string and errors are
  #         ignored.
  #
  # @return [Faraday::ProxySelector::Environment, Faraday::ProxySelector::Nil]
  def self.proxy_with_env(env = nil)
    return ProxySelector::Nil.new if env.nil? && Faraday.ignore_env_proxy

    ProxySelector::Environment.new(env)
  end

  # Builds a ProxySelector that returns the given uri.
  #
  # @param uri [URI] The proxy URI.
  # @param user [String, nil] Optional user info for proxy.
  # @param password [String, nil] Optional password info for proxy.
  #
  # @return [Faraday::ProxySelector::Single]
  def self.proxy_to(uri, user: nil, password: nil)
    ProxySelector::Single.new(uri, user: user, password: password)
  end

  # Builds a ProxySelector that returns the given uri.
  #
  # @param url [String] The proxy raw url.
  # @param user [String, nil] Optional user info for proxy.
  # @param password [String, nil] Optional password info for proxy.
  #
  # @return [Faraday::ProxySelector::Single]
  def self.proxy_to_url(url, user: nil, password: nil)
    proxy_to(Utils.URI(url), user: user, password: password)
  end

  # Proxy is a generic class that knows the Proxy for any given URL. You can
  # initialize a Proxy selector instance with one of the class methods:
  #
  #   # Pulls from ENV
  #   proxy = Faraday.proxy_with_env
  #
  #   # Set your own vars
  #   proxy = Faraday.proxy_with_env(http_proxy: "http://proxy.example.com")
  #
  #   # Set with string URL
  #   proxy = Faraday.proxy_to_url("http://proxy.example.com")
  #
  #   # Set with URI
  #   uri = Faraday::Utils::URI("http://proxy.example.com")
  #   proxy = Faraday.proxy_to(uri) # shortcut
  #
  # Once you have an instance, you can get the proxy for a request url:
  #
  #   proxy.proxy_for_url("http://example.com")
  #   # => Faraday::ProxyOptions instance or nil
  #
  #   uri = Faraday::Utils::URI("http://example.com")
  #   proxy.proxy_for(uri)
  #   # => Faraday::ProxyOptions instance or nil
  class ProxySelector
    # Single is a ProxySelector implementation that always returns the given
    # proxy uri.
    class Single < ProxySelector
      def initialize(uri, user: nil, password: nil)
        @options = ProxyOptions.new(uri, user, password)
      end

      # Gets the configured proxy, regardless of the uri.
      #
      # @param _ [URI] Unused.
      #
      # @return [Faraday::ProxyOptions]
      def proxy_for(_)
        @options
      end

      # Gets the configured proxy, regardless of the url.
      #
      # @param _ [String] Unused.
      #
      # @return [Faraday::ProxyOptions]
      def proxy_for_url(_)
        @options
      end

      # Checks if the given uri has a configured proxy. Returns true, because
      # every request uri should use the configured proxy.
      #
      # @param _ [URI] Unused.
      #
      # @return true
      def use_for?(_)
        !@options.nil?
      end

      # Checks if the given url has a configured proxy. Returns true, because
      # every request url should use the configured proxy.
      #
      # @param _ [String] Unused.
      #
      # @return true
      def use_for_url?(_)
        !@options.nil?
      end
    end
    # Environment is a ProxySelector implementation that picks a proxy based on
    # how the given request url matches with the http_proxy, https_proxy, and
    # no_proxy settings.
    #
    # Note: Logic for parsing proxy env vars heavily inspired by
    # http://golang.org/x/net/http/httpproxy
    class Environment < ProxySelector
      def initialize(env = nil)
        @env = env || ENV
        # parse http_proxy, https_proxy, no_proxy
      end

      # Gets the proxy for the given uri
      #
      # @param uri [URI] URI being requested.
      #
      # @return [Faraday::ProxyOptions, nil]
      def proxy_for(uri)
        # check for proxy based on uri scheme
        # check no_proxy
        raise NotImplementedError, "given: #{uri.inspect}"
      end

      # Gets the proxy for the given url
      #
      # @param url [String] URL being requested.
      #
      # @return [Faraday::ProxyOptions, nil]
      def proxy_for_url(url)
        proxy_for(Utils.URI(url))
      end

      # Checks if the given uri has a configured proxy.
      #
      # @param uri [URI] URI being requested.
      #
      # @return [Bool]
      def use_for?(uri)
        # check for proxy based on uri scheme
        # check no_proxy
        raise NotImplementedError, "given: #{uri.inspect}"
      end

      # Checks if the given url has a configured proxy.
      #
      # @param url [String] URL being requested.
      #
      # @return [Bool]
      def use_for_url?(url)
        use_for?(Utils.URI(url))
      end
    end

    # Nil is a ProxySelector implementation that always returns no proxy. Used
    # if no proxy is manually configured, and Faraday.ignore_env_proxy is
    # enabled.
    class Nil < Single
      def initialize; end
    end
  end
end
