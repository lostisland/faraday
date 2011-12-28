# Faraday.artifice.activate_with(rack_app) do
#   Faraday.new(:url => 'https://graph.facebook.com').get('/btaylor')
# end
module Faraday
  class Artifice

    # Drop a rack endpoint in front of all requests by switching to the
    # Artifice adapter.
    #
    # Example:
    #   Faraday.artifice.activate_with(proc { |env| [200, {}, ['hello']] }) do
    #     Faraday.new.get('/').body # => 'hello'
    #   end
    def activate_with(endpoint)
      activate
      self.endpoint = endpoint
      yield if block_given?
    ensure
      deactivate if block_given?
    end

    def activate
      if Faraday.default_adapter != :artifice
        @default_adapter = Faraday.default_adapter
      end
      Faraday.default_adapter = :artifice
    end

    def deactivate
      Faraday.default_adapter = @default_adapter
    end

    def endpoint=(endpoint)
      Faraday::Adapter::Artifice.endpoint = endpoint
    end

    def endpoint
      Faraday::Adapter::Artifice.endpoint
    end
  end
end