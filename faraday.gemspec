Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5") if s.respond_to? :required_rubygems_version=

  s.name    = 'faraday'
  s.version = '0.8.4'

  s.summary     = "HTTP/REST API client library."
  # TODO: s.description

  s.authors  = ["Rick Olson"]
  s.email    = 'technoweenie@gmail.com'
  s.homepage = 'https://github.com/technoweenie/faraday'

  s.add_dependency 'multipart-post', '~> 1.1'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'test-unit'

  # = MANIFEST =
  s.files = %w[
    Gemfile
    LICENSE.md
    README.md
    Rakefile
    faraday.gemspec
    lib/faraday.rb
    lib/faraday/adapter.rb
    lib/faraday/adapter/em_http.rb
    lib/faraday/adapter/em_synchrony.rb
    lib/faraday/adapter/em_synchrony/parallel_manager.rb
    lib/faraday/adapter/excon.rb
    lib/faraday/adapter/net_http.rb
    lib/faraday/adapter/net_http_persistent.rb
    lib/faraday/adapter/patron.rb
    lib/faraday/adapter/rack.rb
    lib/faraday/adapter/test.rb
    lib/faraday/adapter/typhoeus.rb
    lib/faraday/builder.rb
    lib/faraday/connection.rb
    lib/faraday/error.rb
    lib/faraday/middleware.rb
    lib/faraday/request.rb
    lib/faraday/request/authorization.rb
    lib/faraday/request/basic_authentication.rb
    lib/faraday/request/multipart.rb
    lib/faraday/request/retry.rb
    lib/faraday/request/token_authentication.rb
    lib/faraday/request/url_encoded.rb
    lib/faraday/response.rb
    lib/faraday/response/logger.rb
    lib/faraday/response/raise_error.rb
    lib/faraday/upload_io.rb
    lib/faraday/utils.rb
    script/test
    test/adapters/default_test.rb
    test/adapters/em_http_test.rb
    test/adapters/em_synchrony_test.rb
    test/adapters/excon_test.rb
    test/adapters/integration.rb
    test/adapters/logger_test.rb
    test/adapters/net_http_persistent_test.rb
    test/adapters/net_http_test.rb
    test/adapters/patron_test.rb
    test/adapters/rack_test.rb
    test/adapters/test_middleware_test.rb
    test/adapters/typhoeus_test.rb
    test/authentication_middleware_test.rb
    test/connection_test.rb
    test/env_test.rb
    test/helper.rb
    test/live_server.rb
    test/middleware/retry_test.rb
    test/middleware_stack_test.rb
    test/request_middleware_test.rb
    test/response_middleware_test.rb
  ]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ %r{^test/*/.+\.rb} }
end
