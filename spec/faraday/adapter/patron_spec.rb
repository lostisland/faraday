RSpec.describe Faraday::Adapter::Patron do
  features :reason_phrase_parse

  it_behaves_like 'an adapter'
end