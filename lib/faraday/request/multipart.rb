# frozen_string_literal: true

require File.expand_path('url_encoded', __dir__)
require 'securerandom'

module Faraday
  class Request
    # Middleware for supporting multi-part requests.
    class Multipart < UrlEncoded
      self.mime_type = 'multipart/form-data'
      unless defined?(::Faraday::Request::Multipart::DEFAULT_BOUNDARY_PREFIX)
        DEFAULT_BOUNDARY_PREFIX = '-----------RubyMultipartPost'
      end

      # Checks for files in the payload, otherwise leaves everything untouched.
      #
      # @param env [Faraday::Env]
      def call(env)
        match_content_type(env) do |params|
          env.request.boundary ||= unique_boundary
          env.request_headers[CONTENT_TYPE] +=
            "; boundary=#{env.request.boundary}"
          env.body = create_multipart(env, params)
        end
        @app.call env
      end

      # @param env [Faraday::Env]
      def process_request?(env)
        type = request_type(env)
        env.body.respond_to?(:each_key) && !env.body.empty? && (
          (type.empty? && has_multipart?(env.body)) ||
          (type == self.class.mime_type)
        )
      end

      # Returns true if obj is an enumerable with values that are multipart.
      #
      # @param obj [Object]
      # @return [Boolean]
      def has_multipart?(obj) # rubocop:disable Naming/PredicateName
        if obj.respond_to?(:each)
          (obj.respond_to?(:values) ? obj.values : obj).each do |val|
            return true if val.respond_to?(:content_type) || has_multipart?(val)
          end
        end
        false
      end

      # @param env [Faraday::Env]
      # @param params [Hash]
      def create_multipart(env, params)
        boundary = env.request.boundary
        parts = process_params(params) do |key, value|
          part(boundary, key, value)
        end
        parts << Faraday::Parts::EpiloguePart.new(boundary)

        body = Faraday::CompositeReadIO.new(parts)
        env.request_headers[Faraday::Env::ContentLength] = body.length.to_s
        body
      end

      def part(boundary, key, value)
        if value.respond_to?(:to_part)
          value.to_part(boundary, key)
        else
          Faraday::Parts::Part.new(boundary, key, value)
        end
      end

      # @return [String]
      def unique_boundary
        "#{DEFAULT_BOUNDARY_PREFIX}-#{SecureRandom.hex}"
      end

      # @param params [Hash]
      # @param prefix [String]
      # @param pieces [Array]
      def process_params(params, prefix = nil, pieces = nil, &block)
        params.inject(pieces || []) do |all, (key, value)|
          key = "#{prefix}[#{key}]" if prefix

          case value
          when Array
            values = value.inject([]) { |a, v| a << [nil, v] }
            process_params(values, key, all, &block)
          when Hash
            process_params(value, key, all, &block)
          else
            # rubocop:disable Performance/RedundantBlockCall
            all << block.call(key, value)
            # rubocop:enable Performance/RedundantBlockCall
          end
        end
      end
    end
  end
end
