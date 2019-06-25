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
