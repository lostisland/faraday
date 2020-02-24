---
layout: documentation
title: "Usage"
permalink: /usage/
next_name: Customizing the Request
next_link: ./customize
order: 1
---

Make a simple `GET` request by requiring the Faraday gem and using `Faraday.get`:

```ruby
response = Faraday.get 'http://sushi.com/nigiri/sake.json'
```

This returns a `Faraday::Response` object with the response status, headers, and
body.

```ruby
response.status
# => 200

response.headers
# => {"server"=>"sushi.com", "content-type"=>"text/html; charset=utf-8"...

response.body
# => "<html lang=\"en\">...
```

### Requests without a body

Faraday supports the following HTTP verbs that typically don't include a request
body:

* `get`
* `head`
* `delete`
* `trace`

You can specify URI query parameters and HTTP headers when making a request.


```ruby
url = 'http://sushi.com/nigiri/sake.json'
resp = Faraday.get(url, {a: 1}, {'Accept' => 'application/json'})
# => GET http://sushi.com/nigiri/sake.json?a=1
```

[Learn more about parameters encoding][encoding].

### Requests with a body

Faraday also supports HTTP verbs that do include request bodies, though the
optional method arguments are different. Instead of HTTP query params, these
methods accept a request body.

* `post`
* `put`
* `patch`

```ruby
# POST 'application/x-www-form-urlencoded' content
url = 'http://sushi.com/fave'
resp = Faraday.post(url, "choice=sake")

# POST JSON content
resp = Faraday.post(url, '{"choice": "sake"}',
  "Content-Type" => "application/json")
```

#### Form upload

Faraday can automatically convert hashes to values for form or multipart request
bodies.

```ruby
url = 'http://sushi.com/fave'
resp = Faraday.post(url, choice: 'sake')
# => POST 'choice=sake' to http://sushi.com/fave
```

[Learn more about uploading files][multipart].

### Detailed HTTP Requests

All HTTP verbs support a longer form style of making requests. This is handy if
you need to change a lot of the defaults, or if the details of the HTTP request
change according to method arguments. Each of the HTTP verb helpers can yield a
`Faraday::Request` that can be modified before being sent.

This example shows a hypothetical search endpoint that accepts a JSON request
body as the actual search query.

```ruby
resp = Faraday.get('http://sushi.com/search') do |req|
  req.params['limit'] = 100
  req.headers['Content-Type'] = 'application/json'
  req.body = {query: 'salmon'}.to_json
end
# => GET http://sushi.com/search?limit=100
```

### The Connection Object

A more flexible way to use Faraday is to start with a `Faraday::Connection`
object. Connection objects can store a common URL base path or HTTP headers to
apply to every request. All of the HTTP verb helpers described above
(`Faraday.get`, `Faraday.post`, etc) are available on the `Faraday::Connection`
instance.

```ruby
conn = Faraday.new(
  url: 'http://sushi.com',
  params: {param: '1'},
  headers: {'Content-Type' => 'application/json'}
)

resp = conn.get('search') do |req|
  req.params['limit'] = 100
  req.body = {query: 'salmon'}.to_json
end
# => GET http://sushi.com/search?param=1&limit=100
```

A `Faraday::Connection` object can also be used to change the default HTTP
adapter or add custom middleware that runs during Faraday's request/response
cycle.

[Learn more about Middleware](../middleware).

[encoding]:     ../middleware/url-encoded
[multipart]:    ../middleware/multipart
