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
