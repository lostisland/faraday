# frozen_string_literal: true

# Integration test configuration and helpers
#
# This module provides configuration and helpers for integration tests that run
# against real HTTP services in GitHub Actions service containers.
#
# Service URLs are accessed by service name in container jobs (no port mapping needed).
# See .github/workflows/integration-tests.yml for service configuration.

module Faraday
  module IntegrationHelpers
    # Service URLs for GitHub Actions service containers
    # These are accessed by service name when running in container jobs
    HTTPBIN_URL = ENV.fetch('HTTPBIN_URL', 'http://httpbin:8080')
    PROXY_URL = ENV.fetch('PROXY_URL', 'http://proxy:3128') # Future: for proxy tests

    # Helper to create a Faraday connection for integration tests
    #
    # @param url [String] Base URL for the connection
    # @param options [Hash] Connection options
    # @yield [builder] Middleware stack configuration
    # @return [Faraday::Connection]
    def create_integration_connection(url, options = {}, &block)
      Faraday.new(url, options, &block)
    end
  end
end

# Configure RSpec for integration tests
RSpec.configure do |config|
  # Include integration helpers in integration tests
  config.include Faraday::IntegrationHelpers, type: :integration

  # Tag all integration tests for easy filtering
  # Run with: bundle exec rspec --tag integration
  # Skip with: bundle exec rspec --tag ~integration
  config.define_derived_metadata(file_path: %r{/spec/integration/}) do |metadata|
    metadata[:type] = :integration
    metadata[:integration] = true
  end

  # Integration tests may take longer than unit tests
  config.around(:each, type: :integration) do |example|
    # Set a reasonable timeout for integration tests (30 seconds)
    Timeout.timeout(30) do
      example.run
    end
  end
end
