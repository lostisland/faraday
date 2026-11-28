# frozen_string_literal: true

# The hot paths that bench/allocations.rb and bench/timing.rb measure.
#
# Every case uses the test adapter, so no network is involved. A case must
# work on the Faraday version that bench/compare.rb compares against, so use
# only the public API of the last release.
module FaradayBench
  STUBS = Faraday::Adapter::Test::Stubs.new do |stub|
    stub.get('/items') { [200, { 'Content-Type' => 'text/plain' }, 'ok'] }
    stub.post('/items') { [201, { 'Content-Type' => 'application/json' }, '{"id":1}'] }
  end

  PLAIN = Faraday.new(url: 'https://example.com') { |f| f.adapter :test, STUBS }

  JSON_CONN = Faraday.new(url: 'https://example.com') do |f|
    f.request :json
    f.response :json
    f.adapter :test, STUBS
  end

  REQUEST_OPTIONS = Faraday::RequestOptions.new(timeout: 5, open_timeout: 2, context: { trace: 'abc' })

  CONNECTION_OPTIONS = Faraday::ConnectionOptions.new(
    request: { timeout: 5 }, ssl: { verify: true }, headers: { 'A' => '1' }
  )

  QUERY = { 'a' => '1', 'list' => %w[x y], 'nested' => { 'b' => '2', 'c' => '3' } }.freeze
  QUERY_STRING = Faraday::Utils.build_nested_query(QUERY)

  CASES = {
    'Faraday.new' => -> { Faraday.new },
    'Faraday.new(url)' => -> { Faraday.new('https://example.com') },
    'Faraday.new(url:, headers:, request:, ssl:)' => lambda {
      Faraday.new(url: 'https://example.com', headers: { 'A' => '1' },
                  request: { timeout: 5, open_timeout: 2 }, ssl: { verify: true })
    },
    'Faraday.new with middleware block' => lambda {
      Faraday.new('https://example.com') do |f|
        f.request :json
        f.response :json
        f.adapter :test, STUBS
      end
    },
    'conn.get' => -> { PLAIN.get('/items') },
    'conn.post with JSON middleware' => -> { JSON_CONN.post('/items', { name: 'x' }) },
    'RequestOptions#merge' => -> { REQUEST_OPTIONS.merge(timeout: 10) },
    'ConnectionOptions.from(options)' => -> { Faraday::ConnectionOptions.from(CONNECTION_OPTIONS) },
    'Env.from(hash)' => lambda {
      Faraday::Env.from(method: :get, status: 200, body: 'ok', response_headers: { 'A' => '1' })
    },
    'Utils.build_nested_query' => -> { Faraday::Utils.build_nested_query(QUERY) },
    'Utils.parse_nested_query' => -> { Faraday::Utils.parse_nested_query(QUERY_STRING) }
  }.freeze
end
