module Faraday
  class Middleware
    include Rack::Utils

    class << self
      attr_accessor :load_error, :supports_parallel_requests
      alias supports_parallel_requests? supports_parallel_requests

      # valid parallel managers should respond to #run with no parameters.
      # otherwise, return a short wrapper around it.
      def setup_parallel_manager(options = {})
        nil
      end
    end

    def self.loaded?
      @load_error.nil?
    end

    def initialize(app = nil)
      @app = app
    end

    # assume that query and fragment are already encoded properly
    def full_path_for(path, query = nil, fragment = nil)
      full_path = path.dup
      if query && !query.empty?
        full_path << "?#{query}"
      end
      if fragment && !fragment.empty?
        full_path << "##{fragment}"
      end
      full_path
    end

    def process_body_for_request(env)
      # if it's a string, pass it through
      return if env[:body].nil? || env[:body].empty? || !env[:body].respond_to?(:each_key)
      env[:request_headers]['Content-Type'] ||= 'application/x-www-form-urlencoded'
      env[:body] = create_form_params(env[:body])
    end

    def create_form_params(params, base = nil)
      [].tap do |result|
        params.each_key do |key|
          key_str = base ? "#{base}[#{key}]" : key
          value   = params[key]
          wee = (value.kind_of?(Hash) ? create_form_params(value, key_str) : "#{key_str}=#{escape(value.to_s)}")
          result << wee
        end
      end.join("&")
    end
  end
end