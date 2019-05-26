---
layout: page
title: "The Basics"
permalink: /introduction/basics
hide: true
---

A `GET` request can be performed by calling the `.get` class method:

```ruby
response = Faraday.get 'http://sushi.com/nigiri/sake.json'
```

This works if you don't need to set up anything; you can roll with the default middleware
stack and default adapter (see [Faraday::RackBuilder#initialize][rack_builder]).

## The Connection Object

A more flexible way to use Faraday is to start with a Connection object. If you want to keep the same defaults, you can use this syntax:

```ruby
conn = Faraday.new(url: 'http://www.sushi.com')
```

Connections can also take an options hash as a parameter, or be configured with a block.
Check out the [Middleware][middleware] page for more details about how to use this block for configurations.
Since the default middleware stack uses the `url_encoded` middleware and default adapter, use them on building your own middleware stack.

```ruby
conn = Faraday.new(url: 'http://sushi.com') do |faraday|
  # form-encode POST params
  faraday.request :url_encoded
  # log requests and responses to $stdout
  faraday.response :logger
  # make requests with Net::HTTP
  faraday.adapter Faraday.default_adapter
end
```

Once you have the connection object, use it to make HTTP requests. You can pass parameters to it in a few different ways:

```ruby
conn = Faraday.new(url: 'http://sushi.com/nigiri')

## GET ##

response = conn.get 'sake.json'
# => GET http://sushi.com/nigiri/sake.json

# Using an absolute path overrides the path from the connection initializer
response = conn.get '/maki/platters.json'
# => GET http://sushi.com/maki/platters.json
 
# You can then access the response body
response.body

# Path can also be empty. Parameters can be provided as a hash.
conn.get '', { name: 'Maguro' }
# => GET http://sushi.com/nigiri?name=Maguro

conn.get do |req|
  req.url '/search', page: 2
  req.params['limit'] = 100
end
# => GET http://sushi.com/search?limit=100&page=2

## POST ##

# Parameters for POST requests are automatically put in the body as
# www-form-urlencoded.
conn.post '', { name: 'Maguro' }
# => POST "name=maguro" to http://sushi.com/nigiri

# To post as JSON instead of www-form-urlencoded, set the request header
conn.post do |req|
  req.url ''
  req.headers['Content-Type'] = 'application/json'
  req.body = '{ "name": "Unagi" }'
end
# => POST "{ "name": "Unagi" }" to http://sushi.com/nigiri

```

[rack_builder]:   https://github.com/lostisland/faraday/blob/master/lib/faraday/rack_builder.rb
[middleware]:     ../middleware
