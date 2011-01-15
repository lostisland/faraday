source "http://rubygems.org"

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'patron', '~> 0.4'
  gem 'sinatra', '~> 1.1'
  gem 'typhoeus', '~> 0.2'
  gem 'eventmachine', '~> 0.12'
  gem 'em-http-request', '~> 0.3', :require => 'em-http'
  major, minor, patch = RUBY_VERSION.split('.')
  if major.to_i >= 1 && minor.to_i >= 9
    gem 'em-synchrony', '~> 0.2', :require => ['em-synchrony', 'em-synchrony/em-http']
  end
end

gemspec
