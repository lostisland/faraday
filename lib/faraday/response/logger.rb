require 'forwardable'

module Faraday
  class Response::Logger < Response::Middleware
    extend Forwardable

    DEFAULT_OPTIONS = { :bodies => false }

    def initialize(app, logger = nil, options = {})
      super(app)
      @logger = logger || begin
        require 'logger'
        ::Logger.new(STDOUT)
      end
      @options = DEFAULT_OPTIONS.merge(options)
    end

    def_delegators :@logger, :debug, :info, :warn, :error, :fatal

    def call(env)
      info "#{env.method} #{env.url.to_s}"
      debug('request') { dump_headers env.request_headers }
      debug('request') { dump_body(env[:body]) } if env[:body] && log_body?(:request)
      super
    end

    def on_complete(env)
      info('Status') { env.status.to_s }
      debug('response') { dump_headers env.response_headers }
      debug('response') { dump_body env[:body] } if env[:body] && log_body?(:response)
    end

    private

    def dump_headers(headers)
      headers.map { |k, v| "#{k}: #{v.inspect}" }.join("\n")
    end

    def dump_body(body)
      if body.is_a? String
        body
      else
        require 'pp'
        body.pretty_inspect
      end
    end

    def log_body?(type)
      case @options[:bodies]
      when Hash then @options[:bodies][type]
      else @options[:bodies]
      end
    end
  end
end
