# frozen_string_literal: true

lib = 'faraday'
lib_file = File.expand_path("../lib/#{lib}.rb", __FILE__)
File.read(lib_file) =~ /\bVERSION\s*=\s*["'](.+?)["']/
version = Regexp.last_match(1)

Gem::Specification.new do |spec|
  spec.name    = lib
  spec.version = version

  spec.summary = 'HTTP/REST API client library.'

  spec.authors  = ['@technoweenie', '@iMacTia', '@olleolleolle']
  spec.email    = 'technoweenie@gmail.com'
  spec.homepage = 'https://lostisland.github.io/faraday'
  spec.licenses = ['MIT']

  spec.required_ruby_version = '>= 2.4'

  spec.add_dependency 'multipart-post', '>= 1.2', '< 3'
  spec.add_dependency 'ruby2_keywords'

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
