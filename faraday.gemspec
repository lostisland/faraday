lib_file = File.expand_path('../lib/faraday.rb', __FILE__)
File.read(lib_file) =~ /\bVERSION\s*=\s*["'](.+?)["']/
version = $1

Gem::Specification.new do |spec|
  spec.specification_version = 2 if spec.respond_to? :specification_version=
  spec.required_rubygems_version = Gem::Requirement.new(">= 1.3.5") if spec.respond_to? :required_rubygems_version=

  spec.name    = 'faraday'
  spec.version = version

  spec.summary = "HTTP/REST API client library."

  spec.authors  = ["Rick Olson"]
  spec.email    = 'technoweenie@gmail.com'
  spec.homepage = 'https://github.com/technoweenie/faraday'
  spec.licenses = ['MIT']

  spec.add_dependency 'multipart-post', '~> 1.1'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'simplecov'

  spec.files = %w(Gemfile LICENSE.md README.md Rakefile faraday.gemspec script/test)
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("test/**/*.rb")

  dev_null    = File.exist?('/dev/null') ? '/dev/null' : 'NUL'
  git_files   = `git ls-files -z 2>#{dev_null}`
  spec.files &= git_files.split("\0") if $?.success?
end
