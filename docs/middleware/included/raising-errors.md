# Raising Errors

The `RaiseError` middleware raises a `Faraday::Error` exception if an HTTP
response returns with a 4xx or 5xx status code.
This greatly increases the ease of use of Faraday, as you don't have to check
the response status code manually.
These errors add to the list of default errors [raised by Faraday](getting-started/errors.md).

All exceptions are initialized with a hash containing the response `status`, `headers`, and `body`.

```ruby
conn = Faraday.new(url: 'http://httpbingo.org') do |faraday|
  faraday.response :raise_error # raise Faraday::Error on status code 4xx or 5xx
end

begin
  conn.get('/wrong-url') # => Assume this raises a 404 response
rescue Faraday::ResourceNotFound => e
  e.response_status   #=> 404
  e.response_headers  #=> { ... }
  e.response_body     #=> "..."
end
```

Specific exceptions are raised based on the HTTP Status code of the response.

## 4xx Errors

An HTTP status in the 400-499 range typically represents an error
by the client. They raise error classes inheriting from `Faraday::ClientError`.

| Status Code                                                         | Exception Class                     |
|---------------------------------------------------------------------|-------------------------------------|
| [400](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/400) | `Faraday::BadRequestError`          |
| [401](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/401) | `Faraday::UnauthorizedError`        |
| [403](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/403) | `Faraday::ForbiddenError`           |
| [404](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/404) | `Faraday::ResourceNotFound`         |
| [407](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/407) | `Faraday::ProxyAuthError`           |
| [408](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/408) | `Faraday::RequestTimeoutError`      |
| [409](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/409) | `Faraday::ConflictError`            |
| [422](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/422) | `Faraday::UnprocessableEntityError` |
| 4xx (any other)                                                     | `Faraday::ClientError`              |

## 5xx Errors

An HTTP status in the 500-599 range represents a server error, and raises a
`Faraday::ServerError` exception.

It's important to note that this exception is only returned if we receive a response and the
HTTP status in such response is in the 500-599 range.
Other kind of errors normally attributed to errors in the 5xx range (such as timeouts, failure to connect, etc...)
are raised as specific exceptions inheriting from `Faraday::Error`.
See [Faraday Errors](getting-started/errors.md) for more information on these.

### Missing HTTP status

The HTTP response status may be nil due to a malformed HTTP response from the
server, or a bug in the underlying HTTP library. This is considered a server error
and raised as `Faraday::NilStatusError`, which inherits from `Faraday::ServerError`.

## Middleware Options

The behavior of this middleware can be customized with the following options:

| Option              | Default | Description |
|---------------------|---------|-------------|
| **include_request** | true    | When true, exceptions are initialized with request information including `method`, `url`, `url_path`, `params`, `headers`, and `body`. |

### Example Usage

```ruby
conn = Faraday.new(url: 'http://httpbingo.org') do |faraday|
  faraday.response :raise_error, include_request: true
end

begin
  conn.get('/wrong-url') # => Assume this raises a 404 response
rescue Faraday::ResourceNotFound => e
  e.response[:status]              #=> 404
  e.response[:headers]             #=> { ... }
  e.response[:body]                #=> "..."
  e.response[:request][:url_path]  #=> "/wrong-url"
end
```
