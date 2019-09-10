# frozen_string_literal: true

module Faraday
  # Allows multipart posts while specifying headers of a part
  class ParamPart
    def initialize(value, content_type, content_id = nil)
      @value = value
      @content_type = content_type
      @content_id = content_id
    end

    def to_part(boundary, key)
      Faraday::Parts::Part.new(boundary, key, value, headers)
    end

    def headers
      {
        'Content-Type' => content_type,
        'Content-ID' => content_id
      }
    end

    attr_reader :value, :content_type, :content_id
  end
end
