# frozen_string_literal: true

require 'ipaddr'

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
  #         specifying hosts that should be excluded from proxying. See
  #         Faraday::ProxySelector::Environment for more info.
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
    unless ProxySelector::VALID_PROXY_SCHEMES.include?(uri.scheme)
      raise ArgumentError, "invalid proxy url #{uri.to_s.inspect}. " \
                           'Must start with http://, https://, or socks://'
    end

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
    curl = ProxySelector.canonical_proxy_url(url)
    proxy_to(Utils.URI(curl), user: user, password: password)
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
    def self.canonical_proxy_url(url)
      url_dc = url.to_s.downcase
      return url if VALID_PROXY_PREFIXES.any? { |s| url_dc.start_with?(s) }

      VALID_PROXY_PREFIXES[0] + url
    end

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

      # @!method proxy_for_url(_)
      # Gets the configured proxy, regardless of the url.
      #
      # @param _ [String] Unused.
      #
      # @return [Faraday::ProxyOptions]
      alias proxy_for_url proxy_for

      # Checks if the given uri has a configured proxy. Returns true, because
      # every request uri should use the configured proxy.
      #
      # @param _ [URI] Unused.
      #
      # @return true
      def use_for?(_)
        !@options.nil?
      end

      # @!method use_for_url?(_)
      # Checks if the given url has a configured proxy. Returns true, because
      # every request url should use the configured proxy.
      #
      # @param _ [String] Unused.
      #
      # @return true
      alias use_for_url? use_for?
    end

    # Nil is a ProxySelector implementation that always returns no proxy. Used
    # if no proxy is manually configured, and Faraday.ignore_env_proxy is
    # enabled.
    class Nil < Single
      def initialize; end
    end

    # Environment is a ProxySelector implementation that picks a proxy based on
    # how the given request url matches with the http_proxy, https_proxy, and
    # no_proxy settings. Invalid URL values in http_proxy or https_proxy will
    # be ignored if reading from ENV.
    #
    # The no_proxy is a string containing comma-separated values specifying
    # HTTP request hosts that should be excluded from proxying. Hosts can be
    # specified as host names or IP address. See the HostMatcher and IPMatcher
    # classes for the implementation of those respective filters. A single
    # asterisk (*) indicates that no proxying should be done. It's
    # implementation is in AsteriskMatcher.
    #
    # Note: Logic for parsing proxy env vars heavily inspired by
    # http://golang.org/x/net/http/httpproxy
    class Environment < ProxySelector
      attr_reader :http_proxy
      attr_reader :https_proxy
      attr_reader :ip_matchers
      attr_reader :host_matchers

      def initialize(env = nil)
        @http_proxy = parse_proxy(env ||= ENV, HTTP_PROXY_KEYS)
        @https_proxy = parse_proxy(env, HTTPS_PROXY_KEYS)
        parse_no_proxy(env)
      end

      # Gets the proxy for the given uri
      #
      # @param uri [URI] URI being requested.
      #
      # @return [Faraday::ProxyOptions, nil]
      def proxy_for(uri)
        proxy = (uri.scheme == 'https' && @https_proxy) || @http_proxy
        proxy = nil if proxy && !use_for?(uri)
        proxy
      end

      # Gets the proxy for the given url
      #
      # @param url [String] URL being requested.
      #
      # @return [Faraday::ProxyOptions, nil]
      def proxy_for_url(url)
        proxy_for(Utils.URI(url))
      end

      # Checks if the given uri is allowed by the no_proxy setting.
      #
      # @param uri [URI] URI being requested.
      #
      # @return [Bool]
      def use_for?(uri)
        return false if uri.host == 'localhost'

        host_port_use_proxy?(uri.host, uri.port)
      end

      # Checks if the given url is allowed by the no_proxy setting.
      #
      # @param url [String] URL being requested.
      #
      # @return [Bool]
      def use_for_url?(url)
        use_for?(Utils.URI(url))
      end

      private

      def host_port_use_proxy?(host, port)
        return false if @host_matchers.any? { |m| m.matches?(host, port) }

        # attempt to parse every host as an IP
        ip = IPAddr.new(host)
        !(ip.loopback? || @ip_matchers.any? { |m| m.matches?(ip, port) })
      rescue IPAddr::InvalidAddressError
        true
      end

      def parse_proxy(env, keys)
        value = nil
        keys.detect { |k| value = env[k] }
        return nil unless value && !value.empty?

        ProxyOptions.from(self.class.canonical_proxy_url(value))
      end

      def parse_no_proxy(env)
        @ip_matchers = []
        @host_matchers = []
        value = nil
        NO_PROXY_KEYS.detect { |k| value = env[k] }
        return unless value

        value.split(',').each do |entry|
          entry.strip!
          entry.downcase!

          if entry == '*'
            @ip_matchers = @host_matchers = AsteriskMatcher
            break
          end

          parse_no_proxy_entry(entry) unless entry.empty?
        end
        @ip_matchers.freeze
        @host_matchers.freeze
      end

      def parse_no_proxy_entry(entry)
        port, ip, host = parse_entry(entry)
        @ip_matchers << IPMatcher.new(ip, port) if ip
        @host_matchers << HostMatcher.new(host, port) if host
      end

      def parse_entry(entry)
        # This is an IP or IP range with no port
        # Parser raises if IP has port suffix.
        [nil, IPAddr.new(entry), nil]
      rescue IPAddr::InvalidAddressError
        host, port = if /\A(?<h>.*):(?<p>\d+)\z/i =~ entry
                       [h, p.to_i]
                     else
                       [entry, nil]
                     end

        # There is no host part, likely the entry is malformed; ignore.
        return if host.empty?

        begin
          # This is an IP or IP range with explicit port
          return [port, IPAddr.new(host), nil]
        rescue IPAddr::InvalidAddressError # rubocop:disable Lint/HandleExceptions
        end

        # can't parse as IP, assume it's a domain
        [port, nil, host]
      end

      HTTP_PROXY_KEYS = [:http_proxy, 'http_proxy', 'HTTP_PROXY'].freeze
      HTTPS_PROXY_KEYS = [:https_proxy, 'https_proxy', 'HTTPS_PROXY'].freeze
      NO_PROXY_KEYS = [:no_proxy, 'no_proxy', 'NO_PROXY'].freeze
    end

    VALID_PROXY_SCHEMES = Set.new(%w[http https socks5]).freeze
    VALID_PROXY_PREFIXES = %w[http:// https:// socks5://].freeze

    # IPMatcher parses an IP related entry in the no_proxy env variable.
    class IPMatcher
      # @param ip [IPAddr] IP address prefix (1.2.3.4) or an IP address prefix
      #        in CIDR notation (1.2.3.4/8).
      # @param port [Integer, nil] Determines whether a given ip and port
      #        combo must match a specific port, or if any port is valid.
      def initialize(ip, port)
        @ip = ip
        @port = port
      end

      # Determines if the given ip and port are matched by this IPMatcher.
      #
      # @param ip [IPAddr] IP address prefix (1.2.3.4) of the request URL.
      # @param port [Integer] Port of the request URL.
      #
      # @return [Bool]
      def matches?(ip, port)
        return false unless @port.nil? || @port == port

        @ip.include?(ip)
      end
    end

    # HostMatcher parses a no_proxy entry with a domain and optional port. A
    # host name matches that name and all subdomains. A host name with a
    # leading "." matches subdomains only. For example, "foo.com" matches
    # "foo.com" and "bar.foo.com"; ".y.com" matches "x.y.com" but not "y.com".
    class HostMatcher
      # @param host [String] The host name entry from no_proxy.
      # @param port [Integer, nil] Determines whether a given host and port
      #        combo must match a specific port, or if any port is valid.
      def initialize(host, port)
        host = host[1..-1] if host[0..1] == '*.'

        @port = port
        @host = if (@match_host = host[0] != '.')
                  ".#{host}"
                else
                  host
                end
      end

      # Determines if the given host and port are matched by this HostMatcher.
      #
      # @param host [String] Host name of the request URL.
      # @param port [Integer] Port of the request URL.
      #
      # @return [Bool]
      def matches?(host, port)
        return false unless @port.nil? || @port == port
        return true if host.end_with?(@host)

        @match_host && host == @host[1..-1]
      end
    end

    # AsteriskMatcher replaces all ip and host matchers in a
    # ProxySelector::Environment with one that indicates no proxying will be
    # done.
    class AsteriskMatcher
      def self.any?
        true
      end
    end
  end
end
