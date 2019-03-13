# frozen_string_literal: true

module Faraday
  # Extends Connection class to add proxy management functions.
  class Connection
    def initialize_proxy(url, options)
      @manual_proxy = !!options.proxy
      @proxy =
        if options.proxy
          ProxyOptions.from(options.proxy)
        else
          proxy_from_env(url)
        end
      @temp_proxy = @proxy
    end

    def proxy_from_env(url)
      return if Faraday.ignore_env_proxy

      uri = nil
      if URI.parse('').respond_to?(:find_proxy)
        case url
        when String
          uri = Utils.URI(url)
          uri = URI.parse("#{uri.scheme}://#{uri.hostname}").find_proxy
        when URI
          uri = url.find_proxy
        when nil
          uri = find_default_proxy
        end
      else
        warn 'no_proxy is unsupported' if ENV['no_proxy'] || ENV['NO_PROXY']
        uri = find_default_proxy
      end
      ProxyOptions.from(uri) if uri
    end

    def find_default_proxy
      uri = ENV['http_proxy']
      return unless uri && !uri.empty?

      uri = 'http://' + uri if uri !~ /^http/i
      uri
    end

    def proxy_for_request(url)
      return proxy if @manual_proxy

      if url && Utils.URI(url).absolute?
        proxy_from_env(url)
      else
        proxy
      end
    end
  end
end
