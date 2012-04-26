source 'https://rubygems.org'

group :development do
  # in Sinatra ~> 1.4, server settings will be passed that allows
  # settings to passed to underlying web server.
  # Extra SSL options are passed in for integration tests
  # https://github.com/sinatra/sinatra/commit/9a2fa48074db6ffb7742e50c972a15e2f16fbcf7
  gem 'sinatra', :git => "https://github.com/sinatra/sinatra.git"
  gem 'rack-ssl'
end

group :test do
  gem 'em-http-request', '~> 1.0', :require => 'em-http'
  gem 'em-synchrony', '~> 1.0', :require => ['em-synchrony', 'em-synchrony/em-http'], :platforms => :ruby_19
  gem 'excon', '~> 0.6'
  gem 'net-http-persistent', '~> 2.5', :require => false
  gem 'leftright', '~> 0.9', :require => false
  gem 'rack-test', '~> 0.6', :require => 'rack/test'
end

platforms :ruby do
  gem 'patron', '~> 0.4', '> 0.4.1'
  gem 'typhoeus', '~> 0.3', '> 0.3.2'
end

platforms :jruby do
  gem 'jruby-openssl', '~> 0.7'
  gem 'ffi-ncurses', '~> 0.3'
end

gemspec
