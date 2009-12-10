module Faraday
  # Loads each autoloaded constant.  If thread safety is a concern, wrap
  # this in a Mutex.
  def self.load
    constants.each do |const|
      const_get(const) if autoload?(const)
    end
  end

  autoload :Connection, 'faraday/connection'
  autoload :Response,   'faraday/response'

  module Adapter
    autoload :NetHttp, 'faraday/adapter/net_http'
  end
end