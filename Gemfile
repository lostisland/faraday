source 'https://rubygems.org'

group :development do
  gem 'sinatra', '~> 1.2'
end

group :test do
  gem 'em-http-request', '~> 1.0', :require => 'em-http'
  gem 'em-synchrony', '~> 1.0', :require => ['em-synchrony', 'em-synchrony/em-http'], :platforms => :ruby_19
  gem 'excon', '~> 0.6'
  gem 'net-http-persistent', '~> 2.5', :require => false
  gem 'leftright', '~> 0.9', :require => false
end

platforms :ruby do
  gem 'patron', '~> 0.4', '> 0.4.1'
  gem 'typhoeus', '~> 0.3'
end

platforms :jruby do
  gem 'jruby-openssl', '~> 0.7'
  gem 'ffi-ncurses', '~> 0.3'
end

gemspec
