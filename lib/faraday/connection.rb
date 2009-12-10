require 'addressable/uri'
module Faraday
  class Connection
    include Addressable

    def get(url, params = {}, headers = {})
      uri       = URI.parse(url)
      uri.query = params_to_query(params)
      _get(uri, headers)
    end

    def params_to_query(params)
      params.inject([]) do |memo, (key, val)|
        memo << "#{URI.escape(key)}=#{URI.escape(val)}"
      end.join("&")
    end

    def _get(uri, headers)
      raise NotImplementedError
    end
  end
end