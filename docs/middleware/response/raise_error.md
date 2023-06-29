---
layout: documentation
title: "Raise Error Middleware"
permalink: /middleware/raise-error
hide: true
prev_name: Logger Middleware
prev_link: ./logger
top_name: Back to Middleware
top_link: ./list
---

The `RaiseError` middleware raises a `Faraday::Error` exception if an HTTP
response returns with a 4xx or 5xx status code. All exceptions are initialized
providing the response `status`, `headers`, and `body`.

```ruby
conn = Faraday.new(url: 'http://httpbingo.org') do |faraday|
  faraday.response :raise_error # raise Faraday::Error on status code 4xx or 5xx
end

begin
  conn.get('/wrong-url') # => Assume this raises a 404 response
rescue Faraday::ResourceNotFound => e
  e.response[:status]   #=> 404
  e.response[:headers]  #=> { ... }
  e.response[:body]     #=> "..."
end
```

Specific exceptions are raised based on the HTTP Status code, according to the list below:

An HTTP status in the 400-499 range typically represents an error
by the client. They raise error classes inheriting from `Faraday::ClientError`.

* [400](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/400) => `Faraday::BadRequestError`
* [401](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/401) => `Faraday::UnauthorizedError`
* [403](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/403) => `Faraday::ForbiddenError`
* [404](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/404) => `Faraday::ResourceNotFound`
* [407](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/407) => `Faraday::ProxyAuthError`
* [408](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/408) => `Faraday::RequestTimeoutError`
* [409](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/409) => `Faraday::ConflictError`
* [422](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/422) => `Faraday::UnprocessableEntityError`
* 4xx => `Faraday::ClientError`

An HTTP status in the 500-599 range represents a server error, and raises a
`Faraday::ServerError` exception.

* 5xx => `Faraday::ServerError`

The HTTP response status may be nil due to a malformed HTTP response from the
server, or a bug in the underlying HTTP library. It inherits from
`Faraday::ServerError`.

* nil => `Faraday::NilStatusError`
