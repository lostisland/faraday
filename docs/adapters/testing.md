---
layout: documentation
title: "Testing"
permalink: /adapters/testing
hide: true
top_name: Adapters
top_link: ./
---

The built-in Faraday Test adapter lets you define stubbed HTTP requests. This can
be used to mock out network services in an application's unit tests.

The easiest way to do this is to create the stubbed requests when initializing
a `Faraday::Connection`. Stubbing a request by path yields a block with a
`Faraday::Env` object. The stub block expects an Array return value with three
values: an Integer HTTP status code, a Hash of key/value headers, and a
response body.

```ruby
conn = Faraday.new do |builder|
  builder.adapter :test do |stub|
    # block returns an array with 3 items:
    # - Integer response status
    # - Hash HTTP headers
    # - String response body
    stub.get('/ebi') do |env|
      [
        200,
        { 'Content-Type': 'text/plain', },
        'shrimp'
      ]
    end

    # test exceptions too
    stub.get('/boom') do
      raise Faraday::ConnectionFailed
    end
  end
end
```

You can define the stubbed requests outside of the test adapter block:

```ruby
stubs = Faraday::Adapter::Test::Stubs.new do |stub|
  stub.get('/tamago') { |env| [200, {}, 'egg'] }
end
```

This Stubs instance can be passed to a new Connection:

```ruby
conn = Faraday.new do |builder|
  builder.adapter :test, stubs do |stub|
    stub.get('/ebi') { |env| [ 200, {}, 'shrimp' ]}
  end
end
```

It's also possible to stub additional requests after the connection has been
initialized. This is useful for testing.

```ruby
stubs.get('/uni') { |env| [ 200, {}, 'urchin' ]}
```

If you want to stub requests that exactly match a path, parameters, and headers,
`strict_mode` would be useful.

```ruby
stubs = Faraday::Adapter::Test::Stubs.new(strict_mode: true) do |stub|
  stub.get('/ikura?nori=true', 'X-Soy-Sauce' => '5ml' ) { |env| [200, {}, 'ikura gunkan maki'] }
end
```

This stub expects the connection will be called like this:

```ruby
conn.get('/ikura', { nori: 'true' }, { 'X-Soy-Sauce' => '5ml' } )
```

If there are other parameters or headers included, the Faraday Test adapter
will raise `Faraday::Test::Stubs::NotFound`. It also raises the error
if the specified parameters (`nori`) or headers (`X-Soy-Sauce`) are omitted.

You can also enable `strict_mode` after initializing the connection.
In this case, all requests, including ones that have been already stubbed,
will be handled in a strict way.

```ruby
stubs.strict_mode = true
```

Finally, you can treat your stubs as mocks by verifying that all of the stubbed
calls were made. NOTE: this feature is still fairly experimental. It will not
verify the order or count of any stub.

```ruby
stubs.verify_stubbed_calls
```

After the test case is completed (possibly in an `after` hook), you should clear
the default connection to prevent it from being cached between different tests.
This allows for each test to have its own set of stubs

```ruby
Faraday.default_connection = nil
```

## Examples

Working [RSpec] and [test/unit] examples for a fictional JSON API client are
available.

[RSpec]: https://github.com/lostisland/faraday/blob/master/examples/client_spec.rb
[test/unit]: https://github.com/lostisland/faraday/blob/master/examples/client_test.rb
