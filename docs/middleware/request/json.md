---
layout: documentation
title: "JSON Request Middleware"
permalink: /middleware/json-request
hide: true
prev_name: UrlEncoded Middleware
prev_link: ./url-encoded
next_name: Instrumentation Middleware
next_link: ./instrumentation
top_name: Back to Middleware
top_link: ./list
---

The `JSON` request middleware converts a `Faraday::Request#body` hash of key/value pairs into a JSON request body.
The middleware also automatically sets the `Content-Type` header to `application/json`,
processes only requests with matching Content-Type or those without a type and
doesn't try to encode bodies that already are in string form.

### Example Usage

```ruby
conn = Faraday.new(...) do |f|
  f.request :json
  ...
end

conn.post('/', { a: 1, b: 2 })
# POST with
# Content-Type: application/json
# Body: {"a":1,"b":2}
```
