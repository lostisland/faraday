RSpec.describe Faraday::Adapter::HTTPClient do
  features :body_on_get, :reason_phrase_parse, :compression

  it_behaves_like 'an adapter'
end