RSpec.describe Faraday::Adapter::NetHttpPersistent do
  features :body_on_get, :reason_phrase_parse, :compression

  it_behaves_like 'an adapter'

  it 'allows to provide adapter specific configs' do
    url = URI('https://example.com')

    adapter = Faraday::Adapter::NetHttpPersistent.new do |http|
      http.idle_timeout = 123
    end

    http = adapter.send(:net_http_connection, url: url, request: {})
    adapter.send(:configure_request, http, {})

    expect(http.idle_timeout).to eq(123)
  end

  it 'sets max_retries to 0' do
    url = URI('http://example.com')

    adapter = Faraday::Adapter::NetHttpPersistent.new

    http = adapter.send(:net_http_connection, url: url, request: {})
    adapter.send(:configure_request, http, {})

    # `max_retries=` is only present in Ruby 2.5
    expect(http.max_retries).to eq(0) if http.respond_to?(:max_retries=)
  end

  it 'allows to set pool_size on initialize' do
    url = URI('https://example.com')

    adapter = Faraday::Adapter::NetHttpPersistent.new(nil, { pool_size: 5 })

    http = adapter.send(:net_http_connection, url: url, request: {})

    # `pool` is only present in net_http_persistent >= 3.0
    expect(http.pool.size).to eq(5) if http.respond_to?(:pool)
  end
end
