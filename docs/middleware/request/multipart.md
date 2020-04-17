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

* The request's Content-Type is "multipart/form-data"
* Content-Type is unspecified, AND one of the values in the Body responds to
`#content_type`.

Faraday contains a couple helper classes for multipart values:

* `Faraday::FilePart` wraps binary file data with a Content-Type. The file data
can be specified with a String path to a local file, or an IO object.
* `Faraday::ParamPart` wraps a String value with a Content-Type, and optionally
a Content-ID.

Note: `Faraday::ParamPart` was added in Faraday v0.16.0. Before that,
`Faraday::FilePart` was called `Faraday::UploadIO`.

### Example Usage

```ruby
conn = Faraday.new(...) do |f|
  f.request :multipart
  ...
end
```

Payload can be a mix of POST data and multipart values.

```ruby
# regular POST form value
payload = { string: 'value' }

# filename for this value is File.basename(__FILE__)
payload[:file] = Faraday::FilePart.new(__FILE__, 'text/x-ruby')

# specify filename because IO object doesn't know it
payload[:file_with_name] = Faraday::FilePart.new(File.open(__FILE__),
                             'text/x-ruby',
                             File.basename(__FILE__))

# Sets a custom Content-Disposition:
# nil filename still defaults to File.basename(__FILE__)
payload[:file_with_header] = Faraday::FilePart.new(__FILE__,
                               'text/x-ruby', nil,
                               'Content-Disposition' => 'form-data; foo=1')

# Upload raw json with content type
payload[:raw_data] = Faraday::ParamPart.new({a: 1}.to_json, 'application/json')

# optionally sets Content-ID too
payload[:raw_with_id] = Faraday::ParamPart.new({a: 1}.to_json, 'application/json',
                          'foo-123')

conn.post('/', payload)
```
