RSpec.describe Faraday::Adapter::Typhoeus do
  features :request_body_on_query_methods, :parallel, :trace_method, :connect_method

  it_behaves_like 'an adapter'
end
