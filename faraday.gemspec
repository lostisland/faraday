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
  spec.homepage = 'https://github.com/lostisland/faraday'
  spec.licenses = ['MIT']

  spec.required_ruby_version = '>= 1.9'

  spec.add_dependency 'multipart-post', '>= 1.2', '< 3'

  spec.files = `git ls-files -z lib LICENSE.md README.md`.split("\0")
end
