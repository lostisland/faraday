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

Basic and Token authentication are handled by Faraday::Request::BasicAuthentication
and Faraday::Request::TokenAuthentication respectively.
These can be added as middleware manually or through the helper methods.

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

### Custom Authentication

The generic `Authorization` middleware allows you to add any other type of Authorization header.

```ruby
Faraday.new(...) do |conn|
  conn.request :authorization, 'Bearer', 'authentication-token'
end
```
