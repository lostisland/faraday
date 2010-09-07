module Faraday
  class Adapter < Middleware
    extend AutoloadHelper
    autoload_all 'faraday/adapter',
      :ActionDispatch => 'action_dispatch',
      :NetHttp        => 'net_http',
      :Typhoeus       => 'typhoeus',
      :Patron         => 'patron',
      :Test           => 'test'

    register_lookup_modules \
      :action_dispatch => :ActionDispatch,
      :test            => :Test,
      :net_http        => :NetHttp,
      :typhoeus        => :Typhoeus,
      :patron          => :Patron,
      :net_http        => :NetHttp

    def call(env)
      process_body_for_request(env)
    end

    def process_body_for_request(env)
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
  end
end