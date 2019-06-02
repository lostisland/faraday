---
layout: documentation
title: "Retry Middleware"
permalink: /middleware/retry
hide: true
prev_name: UrlEncoded Middleware
prev_link: ./url-encoded
next_name: Instrumentation Middleware
next_link: ./instrumentation
top_name: Back to Middleware
top_link: ./
---

The `Retry` middleware automatically retries requests that fail due to intermittent client
or server errors (such as network hiccups).
By default, it retries 2 times and handles only timeout exceptions.
It can be configured with an arbitrary number of retries, a list of exceptions to handle,
a retry interval, a percentage of randomness to add to the retry interval, and a backoff factor.

### Example Usage

```ruby
# This example will result in a first interval that is random between 0.05
# and 0.075 and a second interval that is random between 0.1 and 0.15.
retry_options = {
  max: 2,
  interval: 0.05,
  interval_randomness: 0.5,
  backoff_factor: 2
}

conn = Faraday.new(...) do |f|
  f.request :retry, retry_options
  ...
end

conn.get('/')
```

### Control when the middleware will retry requests

By default, the `Retry` middleware will only retry idempotent methods and the most common network-related exceptions.
You can change this behaviour by providing the right option when adding the middleware to your connection.

#### Specify which methods will be retried

You can provide a `methods` option with a list of HTTP methods.
This will replace the default list of HTTP methods: `delete`, `get`, `head`, `options`, `put`.

```ruby
retry_options = {
  methods: %i[get post]
}
```

#### Specify which exceptions should trigger a retry

You can provide an `exceptions` option with a list of exceptions that will replace
the default list of network-related exceptions: `Errno::ETIMEDOUT`, `Timeout::Error`, `Faraday::TimeoutError`.
This can be particularly useful when combined with the [RaiseError][raise_error] middleware.

```ruby
retry_options = {
  exceptions: [Faraday::ResourceNotFound, Faraday::UnauthorizedError]
}
```

#### Specify on which response statuses to retry

By default the `Retry` middleware will only retry the request if one of the expected exceptions arise.
However, you can specify a list of HTTP statuses you'd like to be retried. When you do so, the middleware will
check the response `status` code and will retry the request if included in the list.

```ruby
retry_options = {
  retry_statuses: [401, 409]
}
```

#### Specify a custom retry logic

You can also specify a custom retry logic with the `retry_if` option.
This option accepts a block that will receive the `env` object and the exception raised
and should decide if the code should retry still the action or not independent of the retry count.
This would be useful if the exception produced is non-recoverable or if the the HTTP method called is not idempotent.

**NOTE:** this option will only be used for methods that are not included in the `methods` option.
If you want this to apply to all HTTP methods, pass `methods: []` as an additional option.

```ruby
# Retries the request if response contains { success: false }
retry_options = {
  retry_if: -> (env, _exc) { env.body[:success] == 'false' }
}
```

### Call a block on every retry

You can specify a block through the `retry_block` option that will be called every time the request is retried.
There are many different applications for this feature, spacing from instrumentation to monitoring.
Request environment, middleware options, current number of retries and the exception is passed to the block as parameters.
For example, you might want to keep track of the response statuses:

```ruby
response_statuses = []
retry_options = {
  retry_block: -> (env, options, retries, exc) { response_statuses << env.status }
}
``` 


[raise_error]:  ../middleware/raise-error