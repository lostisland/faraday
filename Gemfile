source 'http://rubygems.org'

group :development do
  gem 'sinatra', '~> 1.2'
end

group :test do
  gem 'em-http-request', '~> 1.0', :require => 'em-http'
  gem 'em-synchrony', '~> 1.0', :require => ['em-synchrony', 'em-synchrony/em-http'], :platforms => :ruby_19
  gem 'excon', '~> 0.6'
  gem 'leftright', '~> 0.9', :require => false
  gem 'patron', '~> 0.4'
  gem 'typhoeus', '~> 0.2'
  # ActiveSupport::JSON will be used in ruby 1.8 and Yajl in 1.9; this is to test against both adapters
  gem 'activesupport', '~> 2.3', :require => nil, :platforms => [:ruby_18, :jruby]
  gem 'yajl-ruby', '~> 1.0', :require => 'yajl', :platforms => :ruby_19
end

platforms :jruby do
  gem 'jruby-openssl', '~> 0.7'
  gem 'ffi-ncurses', '~> 0.3'
end

gemspec
