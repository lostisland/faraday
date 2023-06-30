# Quick Start

## Installation

Add this line to your application’s `Gemfile`:

```ruby
gem 'faraday'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install faraday
```

## Usage

### Quick requests

Let's fetch the home page for the wonderful [httpbingo.org](https://httpbingo.org) service.

You can make a simple `GET` request using `Faraday.get`:

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

The recommended way to use Faraday, especially when integrating to 3rd party services and APIs, is to create
a `Faraday::Connection`. The connection initializer allows you to set:

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

### Using Middleware

Configuring your connection or request with predefined headers and parameters is a good start,
but the real power of Faraday comes from its middleware stack.
Middleware are classes that allow you to hook into the request/response cycle and modify the request.
They can help you with things like:
* adding authentication headers
* parsing JSON responses
* logging requests and responses
* raise errors on 4xx and 5xx responses
* and much more!

For example, let's say you want to call an API that:
* requires an authentication token in the `Authorization` header
* expects JSON request bodies
* returns JSON responses

and on top of that, you want to automatically raise errors on 4xx and 5xx responses,
as well as log all requests and responses.

You can easily achieve all of the above by adding the necessary middleware to your connection:

```ruby
conn = Faraday.new(url: 'http://httpbingo.org') do |builder|
  # Calls MyAuthStorage.get_auth_token on each request to get the auth token
  # and sets it in the Authorization header with Bearer scheme.
  builder.request :authorization, 'Bearer', -> { MyAuthStorage.get_auth_token }

  # Sets the Content-Type header to application/json on each request.
  # Also, if the request body is a Hash, it will automatically be encoded as JSON.
  builder.request :json

  # Parses JSON response bodies.
  # If the response body is not valid JSON, it will raise a Faraday::ParsingError.
  builder.response :json

  # Raises an error on 4xx and 5xx responses.
  builder.response :raise_error

  # Logs requests and responses.
  # By default, it only logs the request method and URL, and the request/response headers.
  builder.response :logger
end

# A simple example implementation for MyAuthStorage
class MyAuthStorage
  def self.get_auth_token
    rand(36 ** 8).to_s(36)
  end
end
```

The connection can now be used to make requests.

```ruby
begin
  response = conn.post('post', { payload: 'this ruby hash will become JSON' })
rescue Faraday::Error => e
  # You can handle errors here (4xx/5xx responses, timeouts, etc.)
  puts e.response[:status]
  puts e.response[:body]
end

# At this point, you can assume the request was successful
puts response.body

# I, [2023-06-30T14:27:11.776511 #35368]  INFO -- request: POST http://httpbingo.org/post
# I, [2023-06-30T14:27:11.776646 #35368]  INFO -- request: User-Agent: "Faraday v2.7.8"
# Authorization: "Bearer wibzjgyh"
# Content-Type: "application/json"
# I, [2023-06-30T14:27:12.063897 #35368]  INFO -- response: Status 200
# I, [2023-06-30T14:27:12.064260 #35368]  INFO -- response: access-control-allow-credentials: "true"
# access-control-allow-origin: "*"
# content-type: "application/json; encoding=utf-8"
# date: "Fri, 30 Jun 2023 13:27:12 GMT"
# content-encoding: "gzip"
# transfer-encoding: "chunked"
# server: "Fly/a0b91024 (2023-06-13)"
# via: "1.1 fly.io"
# fly-request-id: "01H467RYRHA0YK4TQSZ7HS8ZFT-lhr"
# cf-team: "19ae1592b8000003bbaedcf400000001"
```

Faraday ships with a number of useful middleware, and you can also write your own.
To learn more about middleware, please check the [Middleware] section.

### Swapping Adapters

Faraday does not make HTTP requests itself, but instead relies on a Faraday adapter to do so.
By default, it will use the `Net::HTTP` adapter, which is part of the Ruby standard library.
Although `Net::HTTP` is the only adapter that ships with Faraday, there are [many other adapters
available as separate gems](https://github.com/lostisland/awesome-faraday#adapters).

Once you have installed an adapter, you can use it by passing the `adapter` option to `Faraday.new`:

```ruby
conn = Faraday.new(url: 'http://httpbingo.org') do |builder|
  builder.adapter :async_http
end
```

To learn more about adapters, including how to write your own, please check the [Adapters] section.


[Adapters]: /adapters/index.md
[Middleware]: /middleware/index.md
