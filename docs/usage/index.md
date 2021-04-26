---
layout: documentation
title: "Usage"
permalink: /usage/
next_name: Customizing the Request
next_link: ./customize
order: 1
---

Let's fetch the home page for the wonderful
[httpbingo.org](https://httpbingo.org) service. Make a simple `GET` request by
requiring the Faraday gem and using `Faraday.get`:

```ruby
require 'faraday'

response = Faraday.get 'http://httpbingo.org'
```

This returns a `Faraday::Response` object with the response status, headers, and
body.

```ruby
response.status
# => 200

response.headers
# => {"server"=>"Fly/c375678 (2021-04-23)", "content-type"=> ...

response.body
# => "<!DOCTYPE html><html> ...
```

### GET

Faraday supports the following HTTP verbs that typically don't include a request
body:

- `get(url, params = nil, headers = nil)`
- `head(url, params = nil, headers = nil)`
- `delete(url, params = nil, headers = nil)`
- `trace(url, params = nil, headers = nil)`

You can specify URI query parameters and HTTP headers when making a request.

```ruby
url = 'http://httpbingo.org/get'
response = Faraday.get(url, {boom: 'zap'}, {'User-Agent' => 'myapp'})
# => GET http://httpbingo.org/get?boom=zap
```

### POST

Faraday also supports HTTP verbs with bodies. Instead of query parameters, these
accept a request body:

- `post(url, body = nil, headers = nil)`
- `put(url, body = nil, headers = nil)`
- `patch(url, body = nil, headers = nil)`

```ruby
url = 'http://httpbingo.org/post'

# POST 'application/x-www-form-urlencoded' content
response = Faraday.post(url, "boom=zap")

# POST JSON content
response = Faraday.post(url, '{"boom": "zap"}',
  "Content-Type" => "application/json")
```

#### Posting Forms

Faraday will automatically convert key/value hashes into proper form bodies.

```ruby
# POST 'application/x-www-form-urlencoded' content
url = 'http://httpbingo.org/post'
response = Faraday.post(url, boom: 'zap')
# => POST 'boom=zap' to http://httpbingo.org/post
```

Faraday can also [upload files][multipart].

### Detailed HTTP Requests

Faraday supports a longer style for making requests. This is handy if you need
to change many of the defaults, or if the details of the HTTP request change
according to method arguments. Each of the HTTP verb helpers can yield a
`Faraday::Request` that can be modified before being sent.

This example shows a hypothetical search endpoint that accepts a JSON request
body as the actual search query.

```ruby
response = Faraday.post('http://httpbingo.org/post') do |req|
  req.params['limit'] = 100
  req.headers['Content-Type'] = 'application/json'
  req.body = {query: 'chunky bacon'}.to_json
end
# => POST http://httpbingo.org/post?limit=100
```

### Customizing Faraday::Connection

You may want to create a `Faraday::Connection` to setup a common config for
multiple requests. The connection object can be configured with things like:

- default request headers & query parameters
- network settings like proxy or timeout
- common URL base path
- Faraday adapter & middleware (see below)

Create a `Faraday::Connection` by calling `Faraday.new`. The HTTP verbs
described above (`get`, `post`, ...) are `Faraday::Connection` methods:

```ruby
conn = Faraday.new(
  url: 'http://httpbingo.org',
  params: {param: '1'},
  headers: {'Content-Type' => 'application/json'}
)

response = conn.post('/post') do |req|
  req.params['limit'] = 100
  req.body = {query: 'chunky bacon'}.to_json
end
# => POST http://httpbingo.org/post?param=1&limit=100
```

### Adapters

Adapters are responsible for actually executing HTTP requests. The default
adapter uses Ruby's `Net::HTTP`, but there are many different adapters
available. You might want to use Faraday with the Typhoeus adapter, for example.
[Learn more about Adapters](../adapters).

### Middleware

Under the hood, Faraday uses a Rack-inspired middleware stack for making
requests. Much of Faraday's power is unlocked with custom middleware. Some
middleware is included with Faraday, and others are in external gems. [Learn
more about Middleware](../middleware).

Here are some of the features that middleware can provide:

- authentication
- caching responses on disk or in memory
- cookies
- following redirects
- JSON encoding/decoding
- logging
- retrying

To use these great features, create a `Faraday::Connection` with `Faraday.new`
and add the correct middleware in a block. For example:

```ruby
require 'faraday_middleware'

conn = Faraday.new do |f|
  f.request :json # encode req bodies as JSON
  f.request :retry # retry transient failures
  f.response :follow_redirects # follow redirects
  f.response :json # decode response bodies as JSON
end
response = conn.get("http://httpbingo.org/get")
```

#### Default Connection, Default Middleware

Remember how we said that Faraday will automatically encode key/value hash
bodies into form bodies? Internally, the top level shortcut methods
`Faraday.get`, `post`, etc. use a simple default `Faraday::Connection`. The only
middleware used for the default connection is `:url_encoded`, which encodes
those form hashes.

Note that if you create your own connection with middleware, it won't encode
form bodies unless you too include the `:url_encoded` middleware!

[encoding]: ../middleware/url-encoded
[multipart]: ../middleware/multipart
