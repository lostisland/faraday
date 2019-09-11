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

The `Multipart` middleware converts a `Faraday::Request#body` Hash of key/value
pairs into a multipart form request, but only under these conditions:

* The Content-Type is "multipart/form-data"
* Content-Type is unspecified, AND one of the values in the Body responds to
`#content_type`.

Faraday contains a couple helper classes for multipart values:

* `Faraday::UploadIO` wraps file data with a Content-Type. The file data can be
specified with a String path to a local file, or an IO object.
* `Faraday::ParamsPart` wraps a String value with a Content-Type, and optionally
a Content-ID.

### Example Usage

```ruby
conn = Faraday.new(...) do |f|
  f.request :multipart
  ...
end
```

Payload can be a mix of POST data and multipart values.

```ruby
payload = {
  string: "value",
  file: Faraday::UploadIO.new(__FILE__, "text/x-ruby"),

  file_with_name: Faraday::UploadIO.new(__FILE__, "text/x-ruby", "copy.rb"),

  file_with_header: Faraday::UploadIO.new(__FILE__, "text/x-ruby", nil,
                      'Content-Disposition' => 'form-data; foo=1'),

  raw_data: Faraday::ParamsPart.new({a: 1}.to_json, "application/json")

  raw_with_id: Faraday::ParamsPart.new({a: 1}.to_json, "application/json",
                 "foo-123")
}

conn.post('/', payload)
```
