## Faraday 1.0

### Errors
* Removes sub-class constants definition from `Faraday::Error`. A sub-class (e.g. `ClientError`) was previously accessible
either through the `Faraday` module (e.g. `Faraday::ClientError`) or through the `Faraday::Error` class (e.g. `Faraday::Error::ClientError`).
The latter is no longer available and the former should be used instead, so check your `rescue`s.
* Introduces a new `Faraday::ServerError` (5xx status codes) alongside the existing `Faraday::ClientError` (4xx status codes).
Please note `Faraday::ClientError` was previously used for both.
* Introduces new Errors that describe the most common REST status codes:
  * Faraday::BadRequestError (400)
  * Faraday::UnauthorizedError (401)
  * Faraday::ForbiddenError (403)
  * Faraday::ProxyAuthError (407). Please note this raised a `Faraday::ConnectionFailed` before.
  * Faraday::UnprocessableEntityError (422)
  
### Adapters
Adapters have been refactored so that they're not middlewares anymore.
This means that they do not take `@app` as an initializer parameter anymore and they don't call `@app.call` anymore.
If you're using a custom adapter, please ensure to change its initializer and `call` method.

### Faraday::Env
The `Faraday::Env` has been refactored by moving all response-related fields into the response.
This means that if you need to access the response `body`, `headers`, `reason_phrase` or `status`, you'll need to pass through the `response`. (e.g. `env.response.headers`)
However, the following helper methods have been introduced in `Faraday::Env` to ensure backwords compatibility when READING these fields: `response_body`, `response_headers`, `reason_phrase` and `status`.
Moreover, since many existing middlewares still rely on the fact that the `body` is overridden after the response, the `body` getter maintains that functionality.
But now you can access the request body even after a request has been completed using the `request_body` getter.

### Middlewares
Middlewares has been refactored, there's no `Faraday::Response::Middleware` class anymore and all "response" middlewares now inherit from the same `Faraday::Middleware` class as the "request" ones.
There's also a new `on_request` callback that works very similarly to `on_complete` and can be used in "request" middlewares to avoid overriding `call`.


### Others
* Dropped support for jruby and Rubinius.
* Officially supports Ruby 2.3+
* In order to specify the adapter you now MUST use the `#adapter` method on the connection builder. If you don't do so and your adapter inherits from `Faraday::Adapter` then Faraday will raise an exception. Otherwise, Faraday will automatically push the default adapter at the end of the stack causing your request to be executed twice.
```ruby
class OfficialAdapter < Faraday::Adapter
  ...
end

class MyAdapter
  ...
end

# This will raise an exception
conn = Faraday.new(...) do |f|
  f.use OfficialAdapter
end

# This will cause Faraday inserting the default adapter at the end of the stack
conn = Faraday.new(...) do |f|
  f.use MyAdapter
end

# You MUST use `adapter` method
conn = Faraday.new(...) do |f|
  f.adapter AnyAdapter
end
```

