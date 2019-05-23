---
layout: page
title: "The Basics"
permalink: /introduction/basics
hide: true
---

A simple `get` request can be performed simply calling the `get` class method:

```ruby
response = Faraday.get 'http://sushi.com/nigiri/sake.json'
```

This works if you don't need to set up anything; you can roll with just the default middleware
stack and default adapter (see [Faraday::RackBuilder#initialize][rack_builder]).

## The Connection Object

A more flexible way to use Faraday is to start with a Connection object. If you want to keep the same defaults, you can use this syntax:

```ruby
conn = Faraday.new(url: 'http://www.sushi.com')
```

Connections can also take an options hash as a parameter or be configured by using a block.
Checkout the [Middleware][middleware] page for more details about how to use this block for configurations.
Since the default middleware stack uses `url_encoded` middleware and default adapter, use them on building your own middleware stack.

```ruby
conn = Faraday.new(url: 'http://sushi.com') do |faraday|
  faraday.request :url_encoded             # form-encode POST params
  faraday.response :logger                 # log requests and responses to $stdout
  faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
end
```

Once you have the connection object, use it to make HTTP requests. You can pass parameters to it in a few different ways:

```ruby
conn = Faraday.new(url: 'http://sushi.com/nigiri')

## GET ##
response = conn.get 'sake.json'             # GET http://sushi.com/nigiri/sake.json

# You can override the path from the connection initializer by using an absolute path
response = conn.get '/maki/platters.json'   # GET http://sushi.com/maki/platters.json
 
# You can then access the response body
response.body

# Path can also be empty. Parameters can be provided as a hash.
conn.get '', { name: 'Maguro' }             # GET http://sushi.com/nigiri?name=Maguro

conn.get do |req|                           # GET http://sushi.com/search?limit=100&page=2
  req.url '/search', page: 2
  req.params['limit'] = 100
end

## POST ##

# In case of a POST request, parameters are automatically put in the body as ww-form-urlencoded. 
conn.post '', { name: 'Maguro' }            # POST "name=maguro" to http://sushi.com/nigiri

# post payload as JSON instead of www-form-urlencoded encoding
conn.post do |req|                          # POST "{ "name": "Unagi" }" to http://sushi.com/nigiri
  req.url ''
  req.headers['Content-Type'] = 'application/json'
  req.body = '{ "name": "Unagi" }'
end
```

[rack_builder]:   https://github.com/lostisland/faraday/blob/master/lib/faraday/rack_builder.rb
[middleware]:     ../middleware
