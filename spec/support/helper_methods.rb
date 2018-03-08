module Faraday
  module HelperMethods
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def features(*features)
        @features = features
      end

      def on_feature(name, &block)
        if @features.nil?
          superclass.on_feature(name, &block) if superclass.respond_to?(:on_feature)
        else
          yield if block_given? and @features.include?(name)
        end
      end
    end

    def ssl_mode?
      ENV['SSL'] == 'yes'
    end

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

    def multipart_file
      Faraday::UploadIO.new(__FILE__, 'text/x-ruby')
    end
  end
end