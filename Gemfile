# frozen_string_literal: true

source 'https://rubygems.org'

# Even though we don't officially support JRuby, this dependency makes Faraday
# compatible with it, so we're leaving it in for jruby users to use it.
gem 'jruby-openssl', '~> 0.11.0', platforms: :jruby

group :development, :test do
  gem 'bake-test-external'
  gem 'coveralls_reborn', require: false
  gem 'pry'
  gem 'rack', '~> 3.0'
  gem 'rake'
  gem 'rspec', '~> 3.7'
  gem 'rspec_junit_formatter', '~> 0.4'
  gem 'simplecov'
  gem 'webmock', '~> 3.4'
end

group :development, :lint do
  gem 'racc', '~> 1.7' # for RuboCop, on Ruby 3.3
  gem 'rubocop'
  gem 'rubocop-packaging', '~> 0.5'
  gem 'rubocop-performance', '~> 1.0'
  gem 'yard-junk'
end

gemspec
