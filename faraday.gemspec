# frozen_string_literal: true

lib = 'faraday'
lib_file = File.expand_path("../lib/#{lib}.rb", __FILE__)
File.read(lib_file) =~ /\bVERSION\s*=\s*["'](.+?)["']/
version = Regexp.last_match(1)

Gem::Specification.new do |spec|
  spec.name    = lib
  spec.version = version

  spec.summary = 'HTTP/REST API client library.'

  spec.authors  = ['Rick Olson']
  spec.email    = 'technoweenie@gmail.com'
  spec.homepage = 'https://github.com/lostisland/faraday'
  spec.licenses = ['MIT']

  spec.metadata = {
    'bug_tracker_uri' =>
      'https://github.com/lostisland/faraday/issues',
    'changelog_uri' =>
      "https://github.com/lostisland/faraday/releases/tag/v#{spec.version}",
    'documentation_uri' =>
      "https://www.rubydoc.info/gems/faraday/#{spec.version}",
    'source_code_uri' =>
      "https://github.com/lostisland/faraday/tree/v#{spec.version}",
    'wiki_uri' =>
      'https://github.com/lostisland/faraday/wiki'
  }

  spec.required_ruby_version = '>= 2.3'

  spec.add_dependency 'multipart-post', '>= 1.2', '< 3'

  spec.require_paths = %w[lib spec/external_adapters]
  spec.files = `git ls-files -z lib spec/external_adapters`.split("\0")
  spec.files += %w[LICENSE.md README.md]
end
