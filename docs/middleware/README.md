# Middleware Usage

A `Faraday::Connection` uses a `Faraday::RackBuilder` to assemble a
Rack-inspired middleware stack for making HTTP requests. Each middleware runs
and passes an Env object around to the next one. After the final middleware has
run, Faraday will return a `Faraday::Response` to the end user.

## Middleware Types

**Request middleware** can modify Request details before the Adapter runs. Most
middleware set Header values or transform the request body based on the
content type.

* `BasicAuthentication` sets the `Authorization` header to the `user:password`
base64 representation.
* `Multipart` converts a `Faraday::Request#body` hash of key/value pairs into a
multipart form request.
* `UrlEncoded` converts a `Faraday::Request#body` hash of key/value pairs into a url-
encoded request body.

**Adapters** make requests. TBD

* `Retry` automatically retries requests that fail due to intermittent client
or server errors (such as network hiccups).
