# Migrating from `rest-client` to `Faraday`

The `rest-client` gem is in maintenance mode, and developers are encouraged to migrate to actively maintained alternatives like [`faraday`](https://github.com/lostisland/faraday). This guide highlights common usage patterns in `rest-client` and how to migrate them to `faraday`.

---

## Quick Comparison

| Task              | rest-client example                                      | faraday example                                                            |
| ----------------- | -------------------------------------------------------- | -------------------------------------------------------------------------- |
| Simple GET        | `RestClient.get("https://httpbingo.org/get")`            | `Faraday.get("https://httpbingo.org/get")`                                 |
| GET with params   | `RestClient.get(url, params: { id: 1 })`                 | `Faraday.get(url, { id: 1 })`                                              |
| POST form data    | `RestClient.post(url, { a: 1 })`                         | `Faraday.post(url, { a: 1 })`                                              |
| POST JSON         | `RestClient.post(url, obj.to_json, content_type: :json)` | `Faraday.post(url, obj.to_json, { 'Content-Type' => 'application/json' })` |
| Custom headers    | `RestClient.get(url, { Authorization: 'Bearer token' })` | `Faraday.get(url, nil, { 'Authorization' => 'Bearer token' })`             |
| Get response body | `response.body`                                          | `response.body`                                                            |
| Get status code   | `response.code`                                          | `response.status`                                                          |
| Get headers       | `response.headers` (returns `Hash<Symbol, String>`)      | `response.headers` (returns `Hash<String, String>`)                        |

---

## Installation

In your `Gemfile`, replace `rest-client` with:

```ruby
gem "faraday"
```

Then run:

```sh
bundle install
```

---

## Basic HTTP Requests

### GET request

**rest-client:**

```ruby
RestClient.get("https://httpbingo.org/get")
```

**faraday:**

```ruby
Faraday.get("https://httpbingo.org/get")
```

---

### GET with Params

**rest-client:**

```ruby
RestClient.get("https://httpbingo.org/get", params: { id: 1, foo: "bar" })
```

**faraday:**

```ruby
Faraday.get("https://httpbingo.org/get", { id: 1, foo: "bar" })
```

---

### POST Requests

**rest-client:**

```ruby
RestClient.post("https://httpbingo.org/post", { foo: "bar" })
```

**faraday:**

```ruby
Faraday.post("https://httpbingo.org/post", { foo: "bar" })
```

---

### Sending JSON

**rest-client:**

```ruby
RestClient.post("https://httpbingo.org/post", { foo: "bar" }.to_json, content_type: :json)
```

**faraday (manual):**

```ruby
Faraday.post("https://httpbingo.org/post", { foo: "bar" }.to_json, { 'Content-Type' => 'application/json' })
```

**faraday (with middleware):**

```ruby
conn = Faraday.new(url: "https://httpbingo.org") do |f|
  f.request :json            # encode request body as JSON and set Content-Type
  f.response :json           # parse response body as JSON
end

conn.post("/post", { foo: "bar" })
```

---

## Handling Responses

**rest-client:**

```ruby
response = RestClient.get("https://httpbingo.org/headers")
response.code    # => 200
response.body    # => "..."
response.headers # => { content_type: "application/json", ... }
```

**faraday:**

> notice headers Hash keys are stringified, not symbolized like in rest-client

```ruby
response = Faraday.get("https://httpbingo.org/headers")
response.status     # => 200
response.body       # => "..."
response.headers    # => { "content-type" => "application/json", ... }
```

---

## Error Handling

**rest-client:**

```ruby
begin
  RestClient.get("https://httpbingo.org/status/404")
rescue RestClient::NotFound => e
  puts e.response.code  # 404
end
```

**faraday:**

> By default, Faraday does **not** raise exceptions for HTTP errors (like 404 or 500); it simply returns the response. If you want exceptions to be raised on HTTP error responses, include the `:raise_error` middleware.
>
> With `:raise_error`, Faraday will raise `Faraday::ResourceNotFound` for 404s and other exceptions for other 4xx/5xx responses.
>
> See also:
>
> * [Dealing with Errors](getting-started/errors.md)
> * [Raising Errors](middleware/included/raising-errors.md)

```ruby
conn = Faraday.new(url: "https://httpbingo.org") do |f|
  f.response :raise_error
end

begin
  conn.get("/status/404")
rescue Faraday::ResourceNotFound => e
  puts e.response[:status]  # 404
end
```

---

## Advanced Request Configuration

**rest-client:**

```ruby
RestClient::Request.execute(method: :get, url: "https://httpbingo.org/get", timeout: 10)
```

**faraday:**

```ruby
conn = Faraday.new(url: "https://httpbingo.org", request: { timeout: 10 })
conn.get("/get")
```

---

## Headers

**rest-client:**

```ruby
RestClient.get("https://httpbingo.org/headers", { Authorization: "Bearer token" })
```

**faraday:**

> Notice headers Hash expects stringified keys.

```ruby
Faraday.get("https://httpbingo.org/headers", nil, { "Authorization" => "Bearer token" })
```

---

## Redirects

**rest-client:**
Automatically follows GET/HEAD redirects by default.

**faraday:**
Use the `follow_redirects` middleware (not included by default):

```ruby
require "faraday/follow_redirects"

conn = Faraday.new(url: "https://httpbingo.org") do |f|
  f.response :follow_redirects
end
```
