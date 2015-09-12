lib = "faraday"
lib_file = File.expand_path("../lib/#{lib}.rb", __FILE__)
File.read(lib_file) =~ /\bVERSION\s*=\s*["'](.+?)["']/
version = $1

Gem::Specification.new do |spec|
  spec.specification_version = 2 if spec.respond_to? :specification_version=
  spec.required_rubygems_version = '>= 1.3.5'

  spec.name    = lib
  spec.version = version

  spec.summary = "HTTP/REST API client library."

  spec.authors  = ["Rick Olson"]
  spec.email    = 'technoweenie@gmail.com'
  spec.homepage = 'https://github.com/lostisland/faraday'
  spec.licenses = ['MIT']

  spec.add_dependency 'multipart-post', '>= 1.2', '< 3'
  spec.add_development_dependency 'bundler', '~> 1.0'

  spec.files = `git ls-files -z lib LICENSE.md README.md`.split("\0")
end
