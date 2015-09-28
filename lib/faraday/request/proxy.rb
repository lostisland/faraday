module Faraday
  # Uses Environment variables to set proxies on a per-connection basis.
  #
  # If a proxy is not explicitly set, the following environment variables
  # are used:
  #   http_proxy, https_proxy, no_proxy
  # (upper case instances are used in the absence of lower case equivalents)
  #
  # The no_proxy list specifies a comma-separated list of domains
  # (and optionally ports) for which the proxy should not be used.
  #
  # Examples:
  #   # uses environment variables
  #   Faraday.new do |conn|
  #     conn.request :proxy
  #     conn.adapter ..
  #   end
  #
  #   # ignores environment variables
  #   Faraday.new do |conn|
  #     conn.request :proxy 'http://my.proxy.com', /
  #                  :user => 'dan', :password => '123'
  #     conn.adapter ..
  #   end
  class Request::Proxy < Faraday::Middleware
    def initialize(app, proxy_url=nil, options={})
      @proxies = {:http => nil, :https => nil}
      parse_proxy_options(proxy_url, options)
      super(app)
    end

    def call(env)
      env[:request][:proxy] = proxy_for(env.url)
      @app.call(env)
    end

    private
    def parse_proxy_options(proxy, options)
      if proxy.is_a?(Hash)
        options = proxy
        proxy = options.delete(:uri)
      end

      parse_proxies(proxy, options)
      parse_no_proxy_list
    end

    def parse_proxies(uri=nil, options={})
      proxy = parse_uri(uri)

      case proxy.scheme
      when 'http'
        @proxies[:http]  = parse_proxy_uri('http_proxy',  uri, options)
      when 'https'
        @proxies[:https] = parse_proxy_uri('https_proxy', uri, options)
      when nil
        # set both proxies according to ENV variables
        @proxies[:http]  = parse_proxy_uri('http_proxy',  nil, options)
        @proxies[:https] = parse_proxy_uri('https_proxy', nil, options)
      else
        raise ::TypeError, \
          "#{uri} is not a http(s) proxy URL."
      end
    end

    def parse_proxy_uri(proxy_type, uri, options)
      proxy = uri || ENV[proxy_type.downcase] || ENV[proxy_type.upcase]

      proxy_uri = parse_uri(proxy)

      if options.include?(:user)
        proxy_uri.user = options[:user]
      end

      if options.include?(:password)
        proxy_uri.password = options[:password]
      end

      proxy_uri = nil if proxy_uri.scheme == nil

      proxy_uri
    end

    def parse_no_proxy_list
      @no_proxy ||= nil
      proxy_list = ENV['no_proxy'] || ENV['NO_PROXY']
      @no_proxy = proxy_list.split(',') unless proxy_list.nil?
    end

    def proxy_for(uri)
      {:uri => @proxies[uri.scheme.to_sym]} if proxy_allowed_for(uri)
    end

    def proxy_allowed_for(uri)
      return true  if uri.nil? || uri.host.nil?
      return false unless @proxies[uri.scheme.to_sym]
      return true  unless @no_proxy

      proxy_required = true

      @no_proxy.each do |no_proxy_domain|
        # ignore wildcards in domain
        no_proxy_uri = no_proxy_domain.gsub('*.','')

        if domains_match? uri, parse_uri(no_proxy_uri)
          proxy_required = false
          break
        end
      end

      proxy_required
    end

    def domains_match?(uri, no_proxy_uri)
      if no_proxy_uri.port == 80
        # domain matching is fine
        uri_pattern       = uri.host
        no_proxy_pattern  = no_proxy_uri.host
      else
        # need to match ports exactly
        uri_pattern       = "#{uri.host}:#{uri.port}"
        no_proxy_pattern  = "#{no_proxy_uri.host}:#{no_proxy_uri.port}"
      end

      uri_pattern.downcase == no_proxy_pattern.downcase
    end

    def parse_uri(uri='')
      uri = uri.to_s
      parsed = Utils::URI(uri)

      # assume strings without scheme are of http
      if parsed.class == URI::Generic && !uri.empty?
        parsed = Utils::URI("http://#{uri}")
      end

      parsed
    end
  end
end
