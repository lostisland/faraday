# Writing custom middleware

!> A template for writing your own middleware is available in the [faraday-middleware-template](https://github.com/lostisland/faraday-middleware-template) repository.

The recommended way to write middleware is to make your middleware subclass `Faraday::Middleware`.
`Faraday::Middleware` simply expects your subclass to implement two methods: `#on_request(env)` and `#on_complete(env)`.
* `#on_request` is called when the request is being built and is given the `env` representing the request.
* `#on_complete` is called after the response has been received (that's right, it already supports parallel mode!) and receives the `env` of the response.

For both `env` parameters, please refer to the [Env Object](getting-started/env-object.md) page.

```ruby
class MyMiddleware < Faraday::Middleware
  def on_request(env)
    # do something with the request
    # env[:request_headers].merge!(...)
  end

  def on_complete(env)
    # do something with the response
    # env[:response_headers].merge!(...)
  end
end
```

## Having more control

For the majority of middleware, it's not necessary to override the `#call` method. You can instead use `#on_request` and `#on_complete`.

However, in some cases you may need to wrap the call in a block, or work around it somehow (think of a begin-rescue, for example).
When that happens, then you can override `#call`. When you do so, remember to call either `app.call(env)` or `super` to avoid breaking the middleware stack call!

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

It's important to do all processing of the response only in the `#on_complete`
block. This enables middleware to work in parallel mode where requests are
asynchronous.

The `request_env` and `response_env` are both [Env Objects](getting-started/env-object.md) but note the amount of
information available in each one will differ based on the request/response lifecycle.

## Accepting configuration options

`Faraday::Middleware` also allows your middleware to accept configuration options.
These are passed in when the middleware is added to the stack, and can be accessed via the `options` getter.

```ruby
class MyMiddleware < Faraday::Middleware
  def on_request(_env)
    # access the foo option
    puts options[:foo]
  end
end

conn = Faraday.new(url: 'http://httpbingo.org') do |faraday|
  faraday.use MyMiddleware, foo: 'bar'
end
```

## Registering your middleware

Users can use your middleware using the class directly, but you can also register it with Faraday so that
it can be used with the `use`, `request` or `response` methods as well.

```ruby
# Register for `use`
Faraday::Middleware.register_middleware(my_middleware: MyMiddleware)

# Register for `request`
Faraday::Request.register_middleware(my_middleware: MyMiddleware)

# Register for `response`
Faraday::Response.register_middleware(my_middleware: MyMiddleware)
```
