---
layout: documentation
title: "Authentication Middleware"
permalink: /middleware/authentication
hide: true
next_name: UrlEncoded Middleware
next_link: ./url-encoded
top_name: Back to Middleware
top_link: ./list
---

The `Faraday::Request::Authorization` middleware allows you to automatically add an `Authorization` header
to your requests. It also features a handy helper to manage Basic authentication.
**Please note the way you use this middleware in Faraday 1.x is different**,
examples are available at the bottom of this page.

```ruby
Faraday.new(...) do |conn|
  conn.request :authorization, 'Bearer', 'authentication-token'
end
```

### With a proc

You can also provide a proc, which will be evaluated on each request:

```ruby
Faraday.new(...) do |conn|
  conn.request :authorization, 'Bearer', -> { MyAuthStorage.get_auth_token }
end
```

### Basic Authentication

The middleware will automatically Base64 encode your Basic username and password:

```ruby
Faraday.new(...) do |conn|
  conn.request :authorization, :basic, 'username', 'password'
end
```

### Faraday 1.x usage

In Faraday 1.x, the way you use this middleware is slightly different:

```ruby
# Basic Auth request
# Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
Faraday.new(...) do |conn|
  conn.request :basic_auth, 'username', 'password'
end

# Token Auth request
# `options` are automatically converted into `key=value` format
# Authorization: Token authentication-token <options>
Faraday.new(...) do |conn|
  conn.request :token_auth, 'authentication-token', **options
end

# Generic Auth Request
# Authorization: Bearer authentication-token
Faraday.new(...) do |conn|
  conn.request :authorization, 'Bearer', 'authentication-token'
end
```
