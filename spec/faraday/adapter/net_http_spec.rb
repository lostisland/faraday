# frozen_string_literal: true

require 'faraday/net_http'

# Even though Faraday::Adapter::NetHttp is not shipped with Faraday anymore,
# this is still useful to test `it_behaves_like 'an adapter'` shared examples.
RSpec.describe Faraday::Adapter::NetHttp do
  features :request_body_on_query_methods, :reason_phrase_parse, :compression, :streaming, :trace_method

  it_behaves_like 'an adapter'
end
