faraday
=======
Modular HTTP client library using middleware heavily inspired by Rack.

This mess is gonna get raw, like sushi. So, haters to the left.

Usage
-----

```ruby
conn = Faraday.new(:url => 'http://sushi.com') do |builder|
  builder.use Faraday::Request::UrlEncoded  # convert request params as "www-form-urlencoded"
  builder.use Faraday::Request::JSON        # encode request params as json
  builder.use Faraday::Response::Logger     # log the request to STDOUT
  builder.use Faraday::Adapter::NetHttp     # make http requests with Net::HTTP

  # or, use shortcuts:
  builder.request  :url_encoded
  builder.request  :json
  builder.response :logger
  builder.adapter  :net_http
end

## GET ##

response = conn.get '/nigiri/sake.json'     # GET http://sushi.com/nigiri/sake.json
response.body

conn.get '/nigiri', 'X-Awesome' => true     # custom request header

conn.get do |req|                           # GET http://sushi.com/search?page=2&limit=100
  req.url '/search', :page => 2
  req.params['limit'] = 100
end

## POST ##

conn.post '/nigiri', { :name => 'Maguro' }  # POST "name=maguro" to http://sushi.com/nigiri

# post payload as JSON instead of "www-form-urlencoded" encoding:
conn.post '/nigiri', payload, 'Content-Type' => 'application/json'

# a more verbose way:
conn.post do |req|
  req.url '/nigiri'
  req.headers['Content-Type'] = 'application/json'
  req.body = { :name => 'Unagi' }
end

## Options ##

conn.get do |req|
  req.url '/search'
  req.options = {
    :timeout => 5,                    # open/read timeout Integer in seconds
    :open_timeout => 2,               # read timeout Integer in seconds
    :proxy => {
      :uri => "http://example.org/",  # proxy server URI
      :user => "me",                  # proxy server username
      :password => "test123"          # proxy server password
    }
  }
end
```

If you're ready to roll with just the bare minimum:

```ruby
# default stack (net/http), no extra middleware:
response = Faraday.get 'http://sushi.com/nigiri/sake.json'
```

Advanced middleware usage
-------------------------
The order in which middleware is stacked is important. Like with Rack, the first middleware on the list wraps all others, while the last middleware is the innermost one, so that's usually the adapter.

```ruby
conn = Faraday.new(:url => 'http://sushi.com') do |builder|
  # POST/PUT params encoders:
  builder.request  :multipart
  builder.request  :url_encoded
  builder.request  :json

  builder.adapter  :net_http
end
```

This request middleware setup affects POST/PUT requests in the following way:

1. `Request::Multipart` checks for files in the payload, otherwise leaves everything untouched;
2. `Request::UrlEncoded` encodes as "application/x-www-form-urlencoded" if not already encoded or of another type
2. `Request::JSON` encodes as "application/json" if not already encoded or of another type

Because "UrlEncoded" is higher on the stack than JSON encoder, it will get to process the request first. Swapping them means giving the other priority. Specifying the "Content-Type" for the request is explicitly stating which middleware should process it.

Examples:

```ruby
payload = { :name => 'Maguro' }

# post payload as JSON instead of urlencoded:
conn.post '/nigiri', payload, 'Content-Type' => 'application/json'

# uploading a file:
payload = { :profile_pic => Faraday::UploadIO.new('avatar.jpg', 'image/jpeg') }

# "Multipart" middleware detects files and encodes with "multipart/form-data":
conn.put '/profile', payload
```

Writing middleware
------------------
Middleware are classes that respond to `call()`. They wrap the request/response cycle.

```ruby
def call(env)
  # do something with the request

  @app.call(env).on_complete do
    # do something with the response
  end
end
```

It's important to do all processing of the response only in the `on_complete` block. This enables middleware to work in parallel mode where requests are asynchronous.

The `env` is a hash with symbol keys that contains info about the request and, later, response. Some keys are:

```
# request phase
:method - :get, :post, ...
:url    - URI for the current request; also contains GET parameters
:body   - POST parameters for :post/:put requests
:request_headers

# response phase
:status - HTTP response status code, such as 200
:body   - the response body
:response_headers
```

Testing
-------

```ruby
# It's possible to define stubbed request outside a test adapter block.
stubs = Faraday::Adapter::Test::Stubs.new do |stub|
  stub.get('/tamago') { [200, {}, 'egg'] }
end

# You can pass stubbed request to the test adapter or define them in a block
# or a combination of the two.
test = Faraday.new do |builder|
  builder.adapter :test, stubs do |stub|
    stub.get('/ebi') {[ 200, {}, 'shrimp' ]}
  end
end

# It's also possible to stub additional requests after the connection has
# been initialized. This is useful for testing.
stubs.get('/uni') {[ 200, {}, 'urchin' ]}

resp = test.get '/tamago'
resp.body # => 'egg'
resp = test.get '/ebi'
resp.body # => 'shrimp'
resp = test.get '/uni'
resp.body # => 'urchin'
resp = test.get '/else' #=> raises "no such stub" error

# If you like, you can treat your stubs as mocks by verifying that all of
# the stubbed calls were made. NOTE that this feature is still fairly
# experimental: It will not verify the order or count of any stub, only that
# it was called once during the course of the test.
stubs.verify_stubbed_calls
```

TODO
----
* support streaming requests/responses
* better stubbing API
* Add curb, em-http, fast_http

Note on Patches/Pull Requests
-----------------------------
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

Supported Rubies
----------------
This library aims to support and is [tested
against](http://travis-ci.org/technoweenie/faraday) the following Ruby
implementations:

* Ruby 1.8.7
* Ruby 1.9.1
* Ruby 1.9.2
* [Rubinius](http://rubini.us)
* [Ruby Enterprise Edition](http://www.rubyenterpriseedition.com/)

If something doesn't work on one of these interpreters, it should be considered
a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be personally responsible for providing patches in a
timely fashion. If critical issues for a particular implementation exist at the
time of a major release, support for that Ruby version may be dropped.

Copyright
---------
Copyright (c) 2009-2011 rick, hobson. See [LICENSE][license] for details.

[license]: https://github.com/technoweenie/faraday/blob/master/LICENSE.md
