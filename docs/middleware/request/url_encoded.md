---
layout: documentation
title: "UrlEncoded Middleware"
permalink: /middleware/url-encoded
hide: true
prev_name: Multipart Middleware
prev_link: ./multipart
next_name: Retry Middleware
next_link: ./retry
top_name: Back to Middleware
top_link: ./list
---

The `UrlEncoded` middleware converts a `Faraday::Request#body` hash of key/value pairs into a url-encoded request body.
The middleware also automatically sets the `Content-Type` header to `application/x-www-form-urlencoded`.
The way parameters are serialized can be [customized][customize].


### Example Usage

```ruby
conn = Faraday.new(...) do |f|
  f.request :url_encoded
  ...
end

conn.post('/', { a: 1, b: 2 })
# POST with
# Content-Type: application/x-www-form-urlencoded
# Body: a=1&b=2
```

Complex structures can also be passed

```ruby
conn.post('/', { a: [1, 3], b: { c: 2, d: 4} })
# POST with
# Content-Type: application/x-www-form-urlencoded
# Body: a%5B%5D=1&a%5B%5D=3&b%5Bc%5D=2&b%5Bd%5D=4
```

[customize]: ../usage/customize/#changing-how-parameters-are-serialized
