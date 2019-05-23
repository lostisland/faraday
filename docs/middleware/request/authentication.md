---
layout: page
title: "Authentication Middleware"
permalink: /middleware/authentication
hide: true
---

Basic and Token authentication are handled by Faraday::Request::BasicAuthentication
and Faraday::Request::TokenAuthentication respectively.
These can be added as middleware manually or through the helper methods.

```ruby
Faraday.new(...) do |conn|
  conn.basic_auth('username', 'password')
end

Faraday.new(...) do |conn|
  conn.token_auth('authentication-token')
end
```