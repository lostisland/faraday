# frozen_string_literal: true

require_relative 'lib/faraday/version'

Gem::Specification.new do |spec|
  spec.name    = 'faraday'
  spec.version = Faraday::VERSION

  spec.summary = 'HTTP/REST API client library.'

  spec.authors  = ['@technoweenie', '@iMacTia', '@olleolleolle']
  spec.email    = 'technoweenie@gmail.com'
  spec.homepage = 'https://lostisland.github.io/faraday'
  spec.licenses = ['MIT']

  spec.required_ruby_version = '>= 2.6'

  spec.add_dependency 'faraday-net_http', '~> 2.0'
  spec.add_dependency 'ruby2_keywords', '>= 0.0.4'

  # Includes `examples` and `spec` to allow external adapter gems to run Faraday unit and integration tests
  spec.files = Dir['CHANGELOG.md', '{examples,lib,spec}/**/*', 'LICENSE.md', 'Rakefile', 'README.md']
  spec.require_paths = %w[lib spec/external_adapters]
  spec.metadata = {
    'homepage_uri' => 'https://lostisland.github.io/faraday',
    'changelog_uri' =>
      "https://github.com/lostisland/faraday/releases/tag/v#{spec.version}",
    'source_code_uri' => 'https://github.com/lostisland/faraday',
    'bug_tracker_uri' => 'https://github.com/lostisland/faraday/issues'
  }
end
