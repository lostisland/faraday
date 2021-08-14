---
layout: documentation
title: "Authentication Middleware"
permalink: /middleware/authentication
hide: true
next_name: Multipart Middleware
next_link: ./multipart
top_name: Back to Middleware
top_link: ./list
---

The `Faraday::Request::Authentication` middleware allows you to automatically add an `Authorization` header
to your requests. It also feature 2 specialised sub-classes that provide useful extra features for Basic Authentication
and Token Authentication requests.

### Any Authentication

The generic `Authorization` middleware allows you to add any type of Authorization header.

```ruby
Faraday.new(...) do |conn|
  conn.request :authorization, 'Bearer', 'authentication-token'
end
```

### Basic Authentication

`BasicAuthentication` adds a 'Basic' type Authorization header to a Faraday request.

```ruby
Faraday.new(...) do |conn|
  conn.request :basic_auth, 'username', 'password'
end
```

### Token Authentication

`TokenAuthentication` adds a 'Token' type Authorization header to a Faraday request.
You can optionally provide a hash of `options` that will be appended to the token.
This is not used anymore in modern web and have been replaced by Bearer tokens.

```ruby
Faraday.new(...) do |conn|
  conn.request :token_auth, 'authentication-token', **options
end
```
