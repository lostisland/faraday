RSpec.describe Faraday::Adapter::Typhoeus do
  features :body_on_get

  it_behaves_like 'an adapter'
end