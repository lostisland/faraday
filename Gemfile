# frozen_string_literal: true

source 'https://rubygems.org'

ruby RUBY_VERSION

gem 'jruby-openssl', '~> 0.8.8', platforms: :jruby

group :development, :test do
  gem 'pry'
  gem 'rake'
end

group :lint, :development do
  gem 'rubocop', '~> 0.84.0'
  gem 'rubocop-performance', '~> 1.0'
end

group :test, :development do
  gem 'coveralls', require: false
  gem 'em-http-request', '>= 1.1', require: 'em-http'
  gem 'em-synchrony', '>= 1.0.3', require: %w[em-synchrony em-synchrony/em-http]
  gem 'excon', '>= 0.27.4'
  gem 'httpclient', '>= 2.2'
  gem 'multipart-parser'
  gem 'net-http-persistent', '~> 3.0'
  gem 'patron', '>= 0.4.2', platforms: :ruby
  gem 'rack', '< 2.1'
  gem 'rack-test', '>= 0.6', require: 'rack/test'
  gem 'rspec', '~> 3.7'
  gem 'rspec_junit_formatter', '~> 0.4'
  gem 'simplecov'
  gem 'typhoeus', '~> 1.4'
  gem 'webmock', '~> 3.4'
end

gemspec
