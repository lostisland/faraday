source 'http://rubygems.org'

group :development do
  gem 'sinatra', '~> 1.2'
end

group :test do
  gem 'em-http-request', '~> 0.3', :require => 'em-http', :platforms => :ruby
  gem 'em-synchrony', '~> 0.2', :require => ['em-synchrony', 'em-synchrony/em-http'], :platforms => :ruby_19
  gem 'excon', '~> 0.6'
  gem 'patron', '~> 0.4', :platforms => :ruby
  gem 'leftright', :require => false
  gem 'typhoeus', '~> 0.2', :platforms => :ruby
  gem 'webmock'
  # ActiveSupport::JSON will be used in ruby 1.8 and Yajl in 1.9; this is to test against both adapters
  gem 'activesupport', '~> 2.3', :require => nil, :platforms => [:ruby_18, :jruby]
  gem 'yajl-ruby', :require => 'yajl', :platforms => :ruby_19
end

platforms :jruby do
  gem 'jruby-openssl', '~> 0.7'
  gem 'ffi-ncurses'
end

gemspec
