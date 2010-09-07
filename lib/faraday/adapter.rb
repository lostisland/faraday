module Faraday
  class Adapter < Middleware
    FORM_TYPE        = 'application/x-www-form-urlencoded'.freeze
    MULTIPART_TYPE   = 'multipart/form-data'.freeze
    CONTENT_TYPE     = 'Content-Type'.freeze
    DEFAULT_BOUNDARY = "-----------RubyMultipartPost".freeze

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

    # Converts a body hash into encoded form params.  This is done as late
    # as possible in the request cycle in case some other middleware wants to
    # act on the request before sending it out.
    #
    # env     - The current request environment Hash.
    # body    - A Hash of keys/values.  Strings and empty values will be
    #           ignored.  Default: env[:body]
    # headers - The Hash of request headers.  Default: env[:request_headers]
    #
    # Returns nothing.  If the body is processed, it is replaced in the 
    # environment for you.
    def process_body_for_request(env, body = env[:body], headers = env[:request_headers])
      return if body.nil? || body.empty? || !body.respond_to?(:each_key)
      if has_multipart?(body)
        env[:request]            ||= {}
        env[:request][:boundary] ||= DEFAULT_BOUNDARY
        headers[CONTENT_TYPE]      = MULTIPART_TYPE + ";boundary=#{env[:request][:boundary]}"
        env[:body] = create_multipart(env, body)
      else
        type = headers[CONTENT_TYPE]
        headers[CONTENT_TYPE] = FORM_TYPE if type.nil? || type.empty?
        env[:body] = create_form_params(body)
      end
    end

    def has_multipart?(body)
      body.values.each do |v|
        if v.respond_to?(:content_type)
          return true
        elsif v.respond_to?(:values)
          return true if has_multipart?(v)
        end
      end
      false
    end

    def create_multipart(env, params, boundary = nil)
      boundary ||= env[:request][:boundary]
      parts      = []
      add_parts_to(boundary, parts, params)
      parts     << Faraday::Parts::EpiloguePart.new(boundary)
      env[:request_headers]['Content-Length'] = parts.inject(0) {|sum,i| sum + i.length }.to_s
      Faraday::CompositeReadIO.new(*parts.map{|p| p.to_io })
    end

    def add_parts_to(boundary, parts, params, base = nil)
      params.each do |key, value|
        key_str = base ? "#{base}[#{key}]" : key
        if value.kind_of?(Hash)
          add_parts_to(boundary, parts, value, key_str)
        else
          parts << Faraday::Parts::Part.new(boundary, key_str, value)
        end
      end
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