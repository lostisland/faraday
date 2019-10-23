lib = "faraday"
lib_file = File.expand_path("../lib/#{lib}.rb", __FILE__)
File.read(lib_file) =~ /\bVERSION\s*=\s*["'](.+?)["']/
version = $1

Gem::Specification.new do |spec|
  spec.name    = lib
  spec.version = version

  spec.summary = "HTTP/REST API client library."

  spec.authors  = ["Rick Olson"]
  spec.email    = 'technoweenie@gmail.com'
  spec.homepage = 'https://lostisland.github.io/faraday'
  spec.licenses = ['MIT']

  spec.required_ruby_version = '>= 1.9'

  spec.add_dependency 'multipart-post', '>= 1.2', '< 3'

  spec.files = `git ls-files -z CHANGELOG.md LICENSE.md README.md Rakefile lib test spec`.split("\0")
  s.metadata    = {
    "homepage_uri" => "https://lostisland.github.io/faraday",
    "changelog_uri" => "https://github.com/lostisland/faraday/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/lostisland/faraday/",
    "bug_tracker_uri" => "https://github.com/lostisland/faraday/issues",
  }
end
