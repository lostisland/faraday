RSpec.describe Faraday::Adapter::Excon do
  features :body_on_get, :reason_phrase_parse

  it_behaves_like 'an adapter'
end