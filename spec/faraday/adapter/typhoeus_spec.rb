RSpec.describe Faraday::Adapter::Typhoeus do
  features :body_on_get, :parallel

  it_behaves_like 'an adapter', skip: true
end