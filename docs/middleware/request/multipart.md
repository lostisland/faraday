---
layout: documentation
title: "Multipart Middleware"
permalink: /middleware/multipart
hide: true
prev_name: Authentication Middleware
prev_link: ./authentication
next_name: UrlEncoded Middleware
next_link: ./url-encoded
top_name: Back to Middleware
top_link: ./list
---

The `Multipart` middleware converts a `Faraday::Request#body` hash of key/value pairs into a multipart form request.
This only happens if the middleware finds an object in the request body that responds to `content_type`.
The middleware also automatically adds the boundary to the request body.
You can use `Faraday::UploadIO` or `Faraday::CompositeReadIO` to wrap your multipart parameters,
which are in turn wrappers of the equivalent classes from the [`multipart-post`][multipart_post] gem.

### Example Usage

```ruby
conn = Faraday.new(...) do |f|
  f.request :multipart
  ...
end
```

Payload can be a mix of POST data and UploadIO objects. 

```ruby
payload = {
  file_name: 'multipart_example.rb',
  file: Faraday::UploadIO.new(__FILE__, 'text/x-ruby')
}

conn.post('/', payload)
# POST with
# Content-Type: "multipart/form-data; boundary=-----------RubyMultipartPost-b7f5d9a9b5f201e7af7d7af730ac4bf4"
# Body: #<Faraday::CompositeReadIO>
```

[multipart_post]:   https://github.com/socketry/multipart-post