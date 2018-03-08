RSpec.describe Faraday::Adapter::NetHttpPersistent do
  features :body_on_get, :reason_phrase_parse

  it_behaves_like 'an adapter'
end