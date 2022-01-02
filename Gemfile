# frozen_string_literal: true

source 'https://rubygems.org'

# Even though we don't officially support JRuby, this dependency makes Faraday
# compatible with it, so we're leaving it in for jruby users to use it.
gem 'jruby-openssl', '~> 0.11.0', platforms: :jruby

group :development, :test do
  gem 'coveralls_reborn', require: false
  gem 'pry'
  gem 'rack', '~> 2.2'
  gem 'rake'
  gem 'rspec', '~> 3.7'
  gem 'rspec_junit_formatter', '~> 0.4'
  gem 'simplecov'
  gem 'webmock', '~> 3.4'
end

group :development, :lint do
  gem 'rubocop'
  gem 'rubocop-packaging', '~> 0.5'
  gem 'rubocop-performance', '~> 1.0'
  gem 'yard-junk'
end

gemspec
