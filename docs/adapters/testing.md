# Testing

The built-in Faraday Test adapter lets define stubbed HTTP requests. This can
be used to mock out network services in an application's unit tests.

The easiest way to do this is to create the stubbed requests when initializing
a `Faraday::Connection`. Stubbing a request by path yields a block with a
`Faraday::Env` object. The stub block expects an Array return value with three
values: an Integer HTTP status code, a Hash of key/value headers, and a
response body.

```ruby
conn = Faraday.new do |builder|
  builder.adapter :test do |stub|
    stub.get('/ebi') do |env|
      [
        200, # status code
        {
          'Content-Type': 'text/plain',
        }, # headers
        'shrimp' # response body
      ]
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

Finally, you can treat your stubs as mocks by verifying that all of the stubbed
calls were made. NOTE: this feature is still fairly experimental. It will not
verify the order or count of any stub.

```ruby
stubs.verify_stubbed_calls
```
