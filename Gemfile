source 'https://rubygems.org'

gem 'ffi-ncurses', '~> 0.3', :platforms => :jruby
gem 'jruby-openssl', '~> 0.7', :platforms => :jruby
gem 'rake'

group :test do
  gem 'coveralls', :require => false
  gem 'em-http-request', '>= 1.0', :require => 'em-http'
  gem 'em-synchrony', '>= 1.0', :require => ['em-synchrony', 'em-synchrony/em-http']
  gem 'excon', '>= 0.25.3'
  gem 'httpclient', '>= 2.2'
  gem 'leftright', '>= 0.9', :require => false
  gem 'minitest', '~> 5.0.5'
  gem 'net-http-persistent', '>= 2.5', :require => false
  gem 'patron', '>= 0.4.2', :platforms => :ruby
  gem 'rack-test', '>= 0.6', :require => 'rack/test'
  gem 'simplecov'
  gem 'sinatra', '~> 1.3'
  gem 'typhoeus', '~> 0.3.3', :platforms => :ruby
end

gemspec
