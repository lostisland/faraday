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

The `RaiseError` middleware checks the response HTTP code and raises an exception if it is a 4xx or 5xx code.
Specific exceptions are raised based on the HTTP Status code, according to the list below:

```
## 4xx HTTP codes
400 => Faraday::BadRequestError
401 => Faraday::UnauthorizedError
403 => Faraday::ForbiddenError
404 => Faraday::ResourceNotFound
407 => Faraday::ProxyAuthError
409 => Faraday::ConflictError
422 => Faraday::UnprocessableEntityError
4xx => Faraday::ClientError (all exceptions above inherit from this one.

## 5xx HTTP codes
5xx => Faraday::ServerError
```

All exceptions classes listed above inherit from `Faraday::Error`, and are initialized providing
the response `status`, `headers` and `body`, available for you to access on rescue:

```ruby
begin
  conn.get('/wrong-url') # => Assume this raises a 404 response
rescue Faraday::ResourceNotFound => e
  e.response[:status]   #=> 404
  e.response[:headers]  #=> { ... }
  e.response[:body]     #=> "..."  
end 
```
