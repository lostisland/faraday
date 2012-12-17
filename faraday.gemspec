Gem::Specification.new do |spec|
  spec.specification_version = 2 if spec.respond_to? :specification_version=
  spec.required_rubygems_version = Gem::Requirement.new(">= 1.3.5") if spec.respond_to? :required_rubygems_version=

  spec.name    = 'faraday'
  spec.version = '0.9.0.pre'

  spec.summary     = "HTTP/REST API client library."
  # TODO: spec.description

  spec.authors  = ["Rick Olson"]
  spec.email    = 'technoweenie@gmail.com'
  spec.homepage = 'https://github.com/technoweenie/faraday'
  spec.licenses = ['MIT']

  spec.add_dependency 'multipart-post', '~> 1.1'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'simplecov'

  # = MANIFEST =
  spec.files = %w(Gemfile LICENSE.md README.md Rakefile faraday.gemspec script/test)
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("test/**/*.rb")
  spec.test_files = Dir.glob("test/**/*.rb")
end
