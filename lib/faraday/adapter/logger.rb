module Faraday
  class Adapter
    class Logger < Faraday::Adapter
      def self.loaded?() false end

      def initialize(app = nil, logger = nil)
        super(app)
        @logger = logger || begin
          require 'logger'
          ::Logger.new(STDOUT)
        end
      end

      def call(env)
        super
        @logger.info "#{env[:method]} #{env[:url].to_s}"
        @logger.debug("request") do
          env[:request_headers].map { |k, v| "#{k}: #{v.inspect}" }.join("\n")
        end

        @app.call(env).on_complete do
          @logger.info("Status") { env[:status].to_s }
          @logger.debug("response") do
            env[:response_headers].map { |k, v| "#{k}: #{v.inspect}" }.join("\n")
          end
        end
      end
    end
  end
end
