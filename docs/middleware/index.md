# Middleware

Under the hood, Faraday uses a Rack-inspired middleware stack for making
requests. Much of Faraday's power is unlocked with custom middleware. Some
middleware is included with Faraday, and others are in external gems.

Here are some of the features that middleware can provide:

- authentication
- caching responses on disk or in memory
- cookies
- following redirects
- JSON encoding/decoding
- logging

To use these great features, create a `Faraday::Connection` with `Faraday.new`
and add the correct middleware in a block. For example:

```ruby
require 'faraday'

conn = Faraday.new do |f|
  f.request :json # encode req bodies as JSON
  f.response :logger # logs request and responses
  f.response :json # decode response bodies as JSON
  f.adapter :net_http # Use the Net::HTTP adapter
end
response = conn.get("http://httpbingo.org/get")
```

### How it Works

A `Faraday::Connection` uses a `Faraday::RackBuilder` to assemble a
Rack-inspired middleware stack for making HTTP requests. Each middleware runs
and passes an Env object around to the next one. After the final middleware has
run, Faraday will return a `Faraday::Response` to the end user.

The order in which middleware is stacked is important. Like with Rack, the first
middleware on the list wraps all others, while the last middleware is the
innermost one. If you want to use a custom [adapter](adapters/index.md), it must
therefore be last.

![Middleware](../_media/middleware.png)

This is what makes things like the "retry middleware" possible.
It doesn't really matter if the middleware was registered as a request or a response one, the only thing that matter is how they're added to the stack.

Say you have the following:

```ruby
Faraday.new(...) do |conn|
  conn.request :authorization
  conn.response :json
  conn.response :parse_dates
end
```

This will result into a middleware stack like this:

```ruby
authorization do
  # authorization request hook
  json do
    # json request hook
    parse_dates do
      # parse_dates request hook
      response = adapter.perform(request)
      # parse_dates response hook
    end
    # json response hook
  end
  # authorization response hook
end
```

In this example, you can see that `parse_dates` is the LAST middleware processing the request, and the FIRST middleware processing the response.
This is why it's important for the adapter to always be at the end of the middleware list.

### Using Middleware

Calling `use` is the most basic way to add middleware to your stack, but most
middleware is conveniently registered in the `request`, `response` or `adapter`
namespaces. All four methods are equivalent apart from the namespacing.

For example, the `Faraday::Request::UrlEncoded` middleware registers itself in
`Faraday::Request` so it can be added with `request`. These two are equivalent:

```ruby
# add by symbol, lookup from Faraday::Request,
# Faraday::Response and Faraday::Adapter registries
conn = Faraday.new do |f|
  f.request :url_encoded
  f.response :logger
  f.adapter :net_http
end
```

or:

```ruby
# identical, but add the class directly instead of using lookups
conn = Faraday.new do |f|
  f.use Faraday::Request::UrlEncoded
  f.use Faraday::Response::Logger
  f.use Faraday::Adapter::NetHttp
end
```

This is also the place to pass options. For example:

```ruby
conn = Faraday.new do |f|
  f.request :logger, bodies: true
end
```

### DEFAULT_OPTIONS

`DEFAULT_OPTIONS` improve the flexibility and customizability of new and existing middleware. Class-level `DEFAULT_OPTIONS` and the ability to set these defaults at the application level compliment existing functionality in which options can be passed into middleware on a per-instance basis.

#### Using DEFAULT_OPTIONS

Using `RaiseError` as an example, you can see that `DEFAULT_OPTIONS` have been defined at the top of the class:

```ruby
  DEFAULT_OPTIONS = { include_request: true }.freeze
```

These options will be set at the class level upon instantiation and referenced as needed within the class. From our same example:

```ruby
  def response_values(env)
  ...
    return response unless options[:include_request]
  ...
```

If the default value provides the desired functionality, no further consideration is needed.

#### Setting Alternative Options per Application

In the case where it is desirable to change the default option for all instances within an application, it can be done by configuring the options in a `/config/initializers` file. For example:

```ruby
# config/initializers/faraday_config.rb

Faraday::Response::RaiseError.default_options = { include_request: false }
```

After app initialization, all instances of the middleware will have the newly configured option(s). They can still be overriden on a per-instance bases (if handled in the middleware), like this:

```ruby
  Faraday.new do |f|
    ...
    f.response :raise_error, include_request: true 
    ...
  end
```

### Available Middleware

The following pages provide detailed configuration for the middleware that ships with Faraday:
* [Authentication](middleware/included/authentication.md)
* [URL Encoding](middleware/included/url-encoding.md)
* [JSON Encoding/Decoding](middleware/included/json.md)
* [Instrumentation](middleware/included/instrumentation.md)
* [Logging](middleware/included/logging.md)
* [Raising Errors](middleware/included/raising-errors.md)

The [Awesome Faraday](https://github.com/lostisland/awesome-faraday/) project
has a complete list of useful, well-maintained Faraday middleware. Middleware is
often provided by external gems, like the
[faraday-retry](https://github.com/lostisland/faraday-retry) gem.

### Detailed Example

Here's a more realistic example:

```ruby
Faraday.new(...) do |conn|
  # POST/PUT params encoder
  conn.request :url_encoded

  # Logging of requests/responses
  conn.response :logger

  # Last middleware must be the adapter
  conn.adapter :net_http
end
```

This request middleware setup affects POST/PUT requests in the following way:

1. `Request::UrlEncoded` encodes as "application/x-www-form-urlencoded" if not
   already encoded or of another type.
2. `Response::Logger` logs request and response headers, can be configured to log bodies as well.

Swapping middleware means giving the other priority. Specifying the
"Content-Type" for the request is explicitly stating which middleware should
process it.
