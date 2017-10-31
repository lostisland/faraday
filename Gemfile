source 'https://rubygems.org'

gem 'ffi-ncurses', '~> 0.3', :platforms => :jruby
gem 'jruby-openssl', '~> 0.8.8', :platforms => :jruby
# Newer versions drop support for Ruby < 1.9.3, but we still support them.
gem 'rake', '< 11.0.0'

group :test do
  gem 'coveralls', :require => false
  gem 'em-http-request', '>= 1.1', :require => 'em-http'
  gem 'em-synchrony', '>= 1.0.3', :require => ['em-synchrony', 'em-synchrony/em-http']
  gem 'addressable', '< 2.4.0'
  gem 'excon', '>= 0.27.4'
  gem 'httpclient', '>= 2.2', '<= 2.8.1'
  gem 'mime-types', '~> 1.25', :platforms => [:jruby, :ruby_18]
  gem 'tins', '~> 1.6.0', :platforms => [:jruby, :ruby_18]
  gem 'cookiejar', '<= 0.3.2', :platforms => [:jruby, :ruby_18]
  gem 'minitest', '>= 5.0.5'
  gem 'net-http-persistent', '>= 2.9.4', '< 3.0.0'
  gem 'patron', '>= 0.4.2', :platforms => :ruby
  gem 'rack-test', '~> 0.6.0', :require => 'rack/test'
  gem 'rest-client', '~> 1.6.0', :platforms => [:jruby, :ruby_18]
  gem 'simplecov'
  gem 'sinatra', '~> 1.3'
  gem 'typhoeus', '~> 0.3.3', :platforms => [:ruby_18, :ruby_19, :ruby_20, :ruby_21]
end

gemspec
