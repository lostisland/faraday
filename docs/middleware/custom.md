---
layout: documentation
title: "Writing Middleware"
permalink: /middleware/custom
hide: true
top_name: Middleware
top_link: ./
prev_name: Available Middleware
prev_link: ./list
---

Middleware are classes that implement a `#call` instance method. They hook into the request/response cycle.

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

### Faraday::Middleware

There's an easier way to write middleware, and it's also the recommended one: make your middleware subclass `Faraday::Middleware`.
`Faraday::Middleware` already implements the `#call` method for you and looks for two methods in your subclass: `#on_request(env)` and `#on_complete(env)`.
`#on_request` is called when the request is being built and is given the `env` representing the request.

`#on_complete` is called after the response has been received (that's right, it already supports parallel mode!) and receives the `env` of the response.

### Do I need to override `#call`?

For the majority of middleware, it's not necessary to override the `#call` method. You can instead use `#on_request` and `#on_complete`.

However, in some cases you may need to wrap the call in a block, or work around it somehow (think of a begin-rescue, for example).
When that happens, then you can override `#call`. When you do so, remember to call either `app.call(env)` or `super` to avoid breaking the middleware stack call!

### Can I find a middleware template somewhere?

Yes, you can! Look at the [`faraday-middleware-template`](https://github.com/lostisland/faraday-middleware-template) repository.
