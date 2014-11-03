# Faraday

Faraday is an HTTP client lib that provides a common interface over many
adapters (such as Net::HTTP) and embraces the concept of Rack middleware when
processing the request/response cycle.

Faraday supports these adapters:

* Net::HTTP
* [Excon][]
* [Typhoeus][]
* [Patron][]
* [EventMachine][]
* [HTTPClient][]

It also includes a Rack adapter for hitting loaded Rack applications through
Rack::Test, and a Test adapter for stubbing requests by hand.

## Usage

```ruby
conn = Faraday.new(:url => 'http://sushi.com') do |faraday|
  faraday.request  :url_encoded             # form-encode POST params
  faraday.response :logger                  # log requests to STDOUT
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

## GET ##

response = conn.get '/nigiri/sake.json'     # GET http://sushi.com/nigiri/sake.json
response.body

conn.get '/nigiri', { :name => 'Maguro' }   # GET http://sushi.com/nigiri?name=Maguro

conn.get do |req|                           # GET http://sushi.com/search?page=2&limit=100
  req.url '/search', :page => 2
  req.params['limit'] = 100
end

## POST ##

conn.post '/nigiri', { :name => 'Maguro' }  # POST "name=maguro" to http://sushi.com/nigiri

# post payload as JSON instead of "www-form-urlencoded" encoding:
conn.post do |req|
  req.url '/nigiri'
  req.headers['Content-Type'] = 'application/json'
  req.body = '{ "name": "Unagi" }'
end

## Per-request options ##

conn.get do |req|
  req.url '/search'
  req.options.timeout = 5           # open/read timeout in seconds
  req.options.open_timeout = 2      # connection open timeout in seconds
end
```

If you don't need to set up anything, you can roll with just the default middleware
stack and default adapter (see [Faraday::RackBuilder#initialize](https://github.com/lostisland/faraday/blob/master/lib/faraday/rack_builder.rb)):

```ruby
response = Faraday.get 'http://sushi.com/nigiri/sake.json'
```

## Advanced middleware usage

The order in which middleware is stacked is important. Like with Rack, the
first middleware on the list wraps all others, while the last middleware is the
innermost one, so that must be the adapter.

```ruby
Faraday.new(...) do |conn|
  # POST/PUT params encoders:
  conn.request :multipart
  conn.request :url_encoded

  conn.adapter :net_http
end
```

This request middleware setup affects POST/PUT requests in the following way:

1. `Request::Multipart` checks for files in the payload, otherwise leaves
  everything untouched;
2. `Request::UrlEncoded` encodes as "application/x-www-form-urlencoded" if not
  already encoded or of another type

Swapping middleware means giving the other priority. Specifying the
"Content-Type" for the request is explicitly stating which middleware should
process it.

Examples:

```ruby
# uploading a file:
payload[:profile_pic] = Faraday::UploadIO.new('/path/to/avatar.jpg', 'image/jpeg')

# "Multipart" middleware detects files and encodes with "multipart/form-data":
conn.put '/profile', payload
```

## Writing middleware

Middleware are classes that implement a `call` instance method. They hook into
the request/response cycle.

```ruby
def call(request_env)
  # do something with the request
  # request_env[:request_headers].merge!(...)

  @app.call(request_env).on_complete do |response_env|
    # do something with the response
    # response_env[:response_headers].merge!(...)
  end
end
```

It's important to do all processing of the response only in the `on_complete`
block. This enables middleware to work in parallel mode where requests are
asynchronous.

The `env` is a hash with symbol keys that contains info about the request and,
later, response. Some keys are:

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

## Using Faraday for testing

```ruby
# It's possible to define stubbed request outside a test adapter block.
stubs = Faraday::Adapter::Test::Stubs.new do |stub|
  stub.get('/tamago') { |env| [200, {}, 'egg'] }
end

# You can pass stubbed request to the test adapter or define them in a block
# or a combination of the two.
test = Faraday.new do |builder|
  builder.adapter :test, stubs do |stub|
    stub.get('/ebi') { |env| [ 200, {}, 'shrimp' ]}
  end
end

# It's also possible to stub additional requests after the connection has
# been initialized. This is useful for testing.
stubs.get('/uni') { |env| [ 200, {}, 'urchin' ]}

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

## TODO

* support streaming requests/responses
* better stubbing API

## Supported Ruby versions

This library aims to support and is [tested against][travis] the following Ruby
implementations:

* MRI 1.8.7
* MRI 1.9.2
* MRI 1.9.3
* MRI 2.0.0
* MRI 2.1.0
* [JRuby][]
* [Rubinius][]

If something doesn't work on one of these Ruby versions, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.

## Copyright

Copyright (c) 2009-2013 [Rick Olson](mailto:technoweenie@gmail.com), Zack Hobson.
See [LICENSE][] for details.

[travis]:    http://travis-ci.org/lostisland/faraday
[excon]:     https://github.com/geemus/excon#readme
[typhoeus]:  https://github.com/typhoeus/typhoeus#readme
[patron]:    http://toland.github.com/patron/
[eventmachine]: https://github.com/igrigorik/em-http-request#readme
[httpclient]: https://github.com/nahi/httpclient
[jruby]:     http://jruby.org/
[rubinius]:  http://rubini.us/
[license]:   LICENSE.md
