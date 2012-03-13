# faraday [![Build Status](https://secure.travis-ci.org/technoweenie/faraday.png?branch=master)][travis] [![Dependency Status](https://gemnasium.com/technoweenie/faraday.png?travis)][gemnasium]
Modular HTTP client library that uses middleware. Heavily inspired by Rack.

[travis]: http://travis-ci.org/technoweenie/faraday
[gemnasium]: https://gemnasium.com/technoweenie/faraday

Faraday is a Ruby HTTP client that allows developers to customize its behavior with middlewares. If you're familiar with [Rack](http://rack.rubyforge.org/), then you'll love Faraday for the same reasons. This tutorial will cover common use cases built into Faraday, and also explain how to extend Faraday with custom middleware.

## <a name="basics"></a>Basics

Out of the box, Faraday functions like a normal HTTP client with a easy to use interface.

```ruby
Faraday.get 'http://example.com'
```

Alternatively, you can initialize a `Faraday::Connection` instance:

```ruby
conn = Faraday.new
response = conn.get 'http://example.com'
response.status
response.body

conn.post 'http://example.com', :some_param => 'Some Value'
conn.put  'http://example.com', :other_param => 'Other Value'
conn.delete 'http://example.com/foo'
# head, patch, and options all work similarly
```

Parameters can be set inline as the 2nd hash argument. To specify headers, add optional hash after the parameters argument or set them through an accessor:

```ruby
conn.get 'http://example.com', {}, {'Accept' => 'vnd.github-v3+json'}

conn.params  = {'tesla' => 'coil'}
conn.headers = {'Accept' => 'vnd.github-v3+json'}
```

If you have a restful resource you're accessing with a common base url, you can pass in a `:url` parameter that'll be prefixed to all other calls. Other request options can also be set here.

```ruby
conn = Faraday.new(:url => 'http://example.com/comments')
conn.get '/index'  # GET http://example.com/comments/index
```

All HTTP verb methods can take an optional block that will yield a Faraday::Request object:

```ruby
conn.get '/' do |request|
  request.params['limit'] = 100
  request.headers['Content-Type'] = 'application/json'
  request.body = "{some: body}"
end
```

### File upload

```ruby
payload = { :name => 'Maguro' }

# uploading a file:
payload = { :profile_pic => Faraday::UploadIO.new('avatar.jpg', 'image/jpeg') }

# "Multipart" middleware detects files and encodes with "multipart/form-data":
conn.put '/profile', payload
```

### Authentication

Basic and Token authentication are handled by `Faraday::Request::BasicAuthentication` and `Faraday::Request::TokenAuthentication` respectively. These can be added as middleware manually or through the helper methods.

```ruby
conn.basic_auth('pita', 'ch1ps')
conn.token_auth('pitach1ps-token')
```

### Proxies

To specify an HTTP proxy:

```ruby
Faraday.new(:proxy => 'http://proxy.example.com:80')
Faraday.new(:proxy => {
  :uri      => 'http://proxy.example.com',
  :user     => 'foo',
  :password => 'bar'
})
```

### SSL

See the [Setting up SSL certificates](https://github.com/technoweenie/faraday/wiki/Setting-up-SSL-certificates) wiki page.

```ruby
conn = Faraday.new('https://encrypted.google.com', :ssl => {
  :ca_path => "/usr/lib/ssl/certs"
})
conn.get '/search?q=asdf'
```

## Faraday Middleware

Like a Rack app, a `Faraday::Connection` object has a list of middlewares. Faraday middlewares are passed an `env` hash that has request and response information. Middlewares can manipulate this information before and after a request is executed.

To make this more concrete, let's take a look at a new Faraday::Connection:

```ruby
conn = Faraday.new
conn.builder

> #<Faraday::Builder:0x00000131239308 
    @handlers=[Faraday::Request::UrlEncoded, Faraday::Adapter::NetHttp]>
```

`Faraday::Builder` is analogus to `Rack::Builder`. The newly initialized `Faraday::Connection` object has a middleware `Faraday::Request::UrlEncoded` in front of an adapter `Faraday::Adapter::NetHttp`. When a connection object executes a request, it creates a shared `env` hash, wraps the outer middlewares around each inner middleware, and executes the `call` method. Also like a Rack application, the adapter at the end of the builder chain is what actually executes the request.

Middlewares can be grouped into 3 types: request middlewares, response middlewares, and adapters. The distinction between the three is cosmetic. The following two initializers are equivalent:

```ruby
Faraday.new do |builder|
  builder.request  :retry
  builder.request  :basic_authentication, 'login', 'pass'
  builder.response :logger
  builder.adapter  :net_http
end

Faraday.new do |builder|
  builder.use Faraday::Request::Retry
  builder.use Faraday::Request::BasicAuthentication, 'login', 'pass'
  builder.use Faraday::Response::Logger
  builder.use Faraday::Adapter::NetHttp
end
```

### Using a Different HTTP Adapter

If you wanted to use a different HTTP adapter, you can plug one in. For example, to use a EventMachine friendly client, you can switch to the EMHttp adapter:

```ruby
conn = Faraday.new do |builder|
  builder.use Faraday::Adapter::EMHttp

  # alternative syntax that looks up registered adapters from lib/faraday/adapter.rb
  builder.adapter :em_http
end
```

Currently, the supported adapters are Net::HTTP, EM::HTTP, Excon, and Patron.

### Advanced Middleware Usage

The order in which middleware is stacked is important. Like with Rack, the first middleware on the list wraps all others, while the last middleware is the innermost one, so that's usually the adapter.

```ruby
conn = Faraday.new(:url => 'http://sushi.com') do |builder|
  # POST/PUT params encoders:
  builder.request  :multipart
  builder.request  :url_encoded

  builder.adapter  :net_http
end
```

This request middleware setup affects POST/PUT requests in the following way:

1. `Request::Multipart` checks for files in the payload, otherwise leaves everything untouched;
2. `Request::UrlEncoded` encodes as "application/x-www-form-urlencoded" if not already encoded or of another type

Swapping middleware means giving the other priority. Specifying the "Content-Type" for the request is explicitly stating which middleware should process it.

Examples:

```ruby
payload = { :name => 'Maguro' }

# uploading a file:
payload = { :profile_pic => Faraday::UploadIO.new('avatar.jpg', 'image/jpeg') }

# "Multipart" middleware detects files and encodes with "multipart/form-data":
conn.put '/profile', payload
```

### Modifying the Middleware Stack

Each `Faraday::Connection` instance has a `Faraday::Builder` instance that can be used to manipulate the middlewares stack.

```ruby
conn = Faraday.new
conn.builder.swap(1, Faraday::Adapter::EMHttp)  # replace adapter
conn.builder.insert(0, MyCustomMiddleware)      # add middleware to beginning
conn.builder.delete(MyCustomMiddleware)
```

For a full list of actions, take a look at the `Faraday::Builder` documentation.

### Writing Middleware

Middleware are classes that respond to `call`. They wrap the request/response cycle. When it's time to execute a middleware, it's called with an `env` hash that has information about the request and response. The general interface for a middleware is:

```ruby
class MyCustomMiddleware
  def call(env)
    # do something with the request

    @app.call(env).on_complete do |env|
      # do something with the response
      # env[:response] is now filled in
    end
  end
end
```

It's important to do all processing of the response only in the on_complete block. This enables middleware to work in parallel mode where requests are asynchronous.

`env` is a hash with symbol keys that contains info about the request and response.

```
:method - a symbolized request method (:get, :post, :put, :delete, :option, :patch)
:body   - the request body that will eventually be converted to a string.
:url    - URI instance for the current request.
:status           - HTTP response status code
:request_headers  - hash of HTTP Headers to be sent to the server
:response_headers - Hash of HTTP headers from the server
:parallel_manager - sent if the connection is in parallel mode
:request - Hash of options for configuring the request.
  :timeout      - open/read timeout Integer in seconds
  :open_timeout - read timeout Integer in seconds
  :proxy        - Hash of proxy options
    :uri        - Proxy Server URI
    :user       - Proxy server username
    :password   - Proxy server password
:response - Faraday::Response instance. Available only after `on_complete`
:ssl - Hash of options for configuring SSL requests.
  :ca_path - path to directory with certificates
  :ca_file - path to certificate file
```

### Testing Middleware

Faraday::Adapter::Test is an HTTP adapter middleware that lets you to fake responses.

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

### Useful Middleware

* [faraday-middleware](https://github.com/pengwynn/faraday_middleware) - collection of Faraday middlewares.
* [faraday_yaml](https://github.com/dmarkow/faraday_yaml) - yaml request/response processing

## <a name="todo"></a>TODO
* support streaming requests/responses
* better stubbing API
* Add curb, fast_http

## <a name="pulls"></a>Note on Patches/Pull Requests
1. Fork the project.
2. Make your feature addition or bug fix.
3. Add tests for it. This is important so I don't break it in a future version
   unintentionally.
4. Commit, do not mess with rakefile, version, or history. (if you want to have
   your own version, that is fine but bump version in a commit by itself I can
   ignore when I pull)
5. Send me a pull request. Bonus points for topic branches.

## <a name="versions"></a>Supported Ruby Versions
This library aims to support and is [tested against][travis] the following Ruby
implementations:

* Ruby 1.8.7
* Ruby 1.9.2
* Ruby 1.9.3
* [JRuby][jruby]
* [Rubinius][rubinius]
* [Ruby Enterprise Edition][ree]

[jruby]: http://jruby.org/
[rubinius]: http://rubini.us/
[ree]: http://www.rubyenterpriseedition.com/

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

## <a name="copyright"></a>Copyright
Copyright (c) 2009 [Rick Olson](mailto:technoweenie@gmail.com), zack hobson. See [LICENSE][] for details.

[license]: https://github.com/technoweenie/faraday/blob/master/LICENSE.md