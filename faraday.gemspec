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

  spec.required_ruby_version = '>= 3.0'

  # faraday-net_http is the "default adapter", but being a Faraday dependency it can't
  # control which version of faraday it will be pulled from.
  # To avoid releasing a major version every time there's a new Faraday API, we should
  # always fix its required version to the next MINOR version.
  # This way, we can release minor versions of the adapter with "breaking" changes for older versions of Faraday
  # and then bump the version requirement on the next compatible version of faraday.
  spec.add_dependency 'faraday-net_http', '>= 2.0', '< 3.1'

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
