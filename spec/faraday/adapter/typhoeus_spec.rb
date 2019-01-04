RSpec.describe Faraday::Adapter::Typhoeus do
  features :body_on_get, :parallel

  # Commenting until Typhoeus is updated to support v1.0
  # it_behaves_like 'an adapter'
end