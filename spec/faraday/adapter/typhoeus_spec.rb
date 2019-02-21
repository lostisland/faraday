RSpec.describe Faraday::Adapter::Typhoeus do
  features :body_on_get, :parallel, :trace_method, :connect_method

  it_behaves_like 'an adapter'
end
