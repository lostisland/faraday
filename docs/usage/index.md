---
layout: documentation
title: "Usage"
permalink: /usage/
next_name: Customizing the Request
next_link: ./customize
order: 1
---

Let's fetch the home page for the wonderful
[httpbingo.org](https://httpbingo.org) service.

First of all, you need to tell Faraday which [`adapter`](../adapters) you wish to use.
Adapters are responsible for actually executing HTTP requests.
There are many different adapters you can choose from.
Just pick the one you like and install it, or add it to your project Gemfile.
You might want to use Faraday with the `Net::HTTP` adapter, for example.
[Learn more about Adapters](../adapters).

Remember you'll need to install the corresponding adapter gem before you'll be able to use it.

```ruby
require 'faraday'
require 'faraday/net_http'
Faraday.default_adapter = :net_http
```

Next, you can make a simple `GET` request using `Faraday.get`:

```ruby
response = Faraday.get('http://httpbingo.org')
```

This returns a `Faraday::Response` object with the response status, headers, and body.

```ruby
response.status
# => 200

response.headers
# => {"server"=>"Fly/c375678 (2021-04-23)", "content-type"=> ...

response.body
# => "<!DOCTYPE html><html> ...
```

### Faraday Connection

The recommended way to use Faraday, especially when integrating to 3rd party services and API, is to create
a `Faraday::Connection`. The connection object can be configured with things like:

- default request headers & query parameters
- network settings like proxy or timeout
- common URL base path
- Faraday adapter & middleware (see below)

Create a `Faraday::Connection` by calling `Faraday.new`. You can then call each HTTP verb
(`get`, `post`, ...) on your `Faraday::Connection` to perform a request:

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

### GET, HEAD, DELETE, TRACE

Faraday supports the following HTTP verbs that typically don't include a request body:

- `get(url, params = nil, headers = nil)`
- `head(url, params = nil, headers = nil)`
- `delete(url, params = nil, headers = nil)`
- `trace(url, params = nil, headers = nil)`

You can specify URI query parameters and HTTP headers when making a request.

```ruby
response = conn.get('get', { boom: 'zap' }, { 'User-Agent' => 'myapp' })
# => GET http://httpbingo.org/get?boom=zap
```

### POST, PUT, PATCH

Faraday also supports HTTP verbs with bodies. Instead of query parameters, these
accept a request body:

- `post(url, body = nil, headers = nil)`
- `put(url, body = nil, headers = nil)`
- `patch(url, body = nil, headers = nil)`

```ruby
# POST 'application/x-www-form-urlencoded' content
response = conn.post('post', 'boom=zap')

# POST JSON content
response = conn.post('post', '{"boom": "zap"}',
  "Content-Type" => "application/json")
```

#### Posting Forms

Faraday will automatically convert key/value hashes into proper form bodies
thanks to the `url_encoded` middleware included in the default connection.

```ruby
# POST 'application/x-www-form-urlencoded' content
response = conn.post('post', boom: 'zap')
# => POST 'boom=zap' to http://httpbingo.org/post
```

### Detailed HTTP Requests

Faraday supports a longer style for making requests. This is handy if you need
to change many of the defaults, or if the details of the HTTP request change
according to method arguments. Each of the HTTP verb helpers can yield a
`Faraday::Request` that can be modified before being sent.

This example shows a hypothetical search endpoint that accepts a JSON request
body as the actual search query.

```ruby
response = conn.post('post') do |req|
  req.params['limit'] = 100
  req.headers['Content-Type'] = 'application/json'
  req.body = {query: 'chunky bacon'}.to_json
end
# => POST http://httpbingo.org/post?limit=100
```

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
require 'faraday'
require 'faraday/retry'

conn = Faraday.new('http://httpbingo.org') do |f|
  f.request :json # encode req bodies as JSON and automatically set the Content-Type header
  f.request :retry # retry transient failures
  f.response :json # decode response bodies as JSON
  f.adapter :net_http # adds the adapter to the connection, defaults to `Faraday.default_adapter`
end

# Sends a GET request with JSON body that will automatically retry in case of failure.
response = conn.get('get', boom: 'zap')

# response body is automatically decoded from JSON to a Ruby hash
response.body['args'] #=> {"boom"=>["zap"]}
```

#### Default Connection, Default Middleware

Remember how we said that Faraday will automatically encode key/value hash
bodies into form bodies? Internally, the top level shortcut methods
`Faraday.get`, `post`, etc. use a simple default `Faraday::Connection`. The only
middleware used for the default connection is `:url_encoded`, which encodes
those form hashes, and the `default_adapter`.

Note that if you create your own connection with middleware, it won't encode
form bodies unless you too include the [`:url_encoded`][encoding] middleware!

[encoding]:   ../middleware/url-encoded
