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

```ruby
Faraday.new(...) do |conn|
  conn.basic_auth('username', 'password')
end
```

### Token Authentication

```ruby
Faraday.new(...) do |conn|
  conn.token_auth('authentication-token')
end
```