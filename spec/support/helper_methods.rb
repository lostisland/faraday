module Faraday
  module HelperMethods
    def normalize(url)
      Faraday::Utils::URI(url)
    end

    def with_default_uri_parser(parser)
      old_parser = Faraday::Utils.default_uri_parser
      begin
        Faraday::Utils.default_uri_parser = parser
        yield
      ensure
        Faraday::Utils.default_uri_parser = old_parser
      end
    end

    def capture_warnings
      old, $stderr = $stderr, StringIO.new
      begin
        yield
        $stderr.string
      ensure
        $stderr = old
      end
    end
  end
end