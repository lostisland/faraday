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

The `Faraday::Request::Authorization` middleware allows you to automatically add an `Authorization` header
to your requests. It also features a handy helper to manage Basic authentication.

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
