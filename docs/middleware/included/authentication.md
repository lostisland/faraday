# Authentication

The `Faraday::Request::Authorization` middleware allows you to automatically add an `Authorization` header
to your requests. It also features a handy helper to manage Basic authentication.
**Please note the way you use this middleware in Faraday 1.x is different**;
examples are available at the bottom of this page.

The middleware signature is:

```ruby
conn.request :authorization, type, *params
```

- Except for Basic authentication (`:basic` / `'Basic'`, matched case-insensitively with two arguments), Faraday does **not** restrict `type` to a fixed list of schemes. Any `String` or `Symbol` is accepted and interpolated verbatim as `Authorization: <type> <value>` (for example, `'Token'` produces `Token ...`, while `:token` produces `token ...`).
- For non-Basic schemes, a single `value` argument is expected; passing additional arguments raises `ArgumentError`.
- If a request already has an `Authorization` header (for example, set on an individual request), the middleware leaves it unchanged.

### Bearer Authentication

```ruby
# Authorization: Bearer authentication-token
Faraday.new(...) do |conn|
  conn.request :authorization, 'Bearer', 'authentication-token'
end
```

### Basic Authentication

When `type` is `:basic` (or `'Basic'`, case-insensitive) and two arguments are provided, the middleware automatically Base64-encodes `username:password`:

```ruby
# Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
Faraday.new(...) do |conn|
  conn.request :authorization, :basic, 'username', 'password'
end
```

You can also pass a single pre-encoded credential string:

```ruby
# Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
Faraday.new(...) do |conn|
  conn.request :authorization, 'Basic', 'dXNlcm5hbWU6cGFzc3dvcmQ='
end
```

### Token Authentication

Because Faraday interpolates `type` and the single `value` directly, use `'Token'` (or `:Token`) for a capitalized scheme name and format the value to match what your API expects:

```ruby
# Plain token (e.g. Authorization: Token authentication-token)
Faraday.new(...) do |conn|
  conn.request :authorization, 'Token', 'authentication-token'
end

# Parameterized token (e.g. Authorization: Token token="authentication-token", foo="bar")
Faraday.new(...) do |conn|
  conn.request :authorization, 'Token', 'token="authentication-token", foo="bar"'
end
```

Unlike Faraday 1.x's `:token_auth` middleware, Faraday 2.x does not automatically serialize a `token` and options `Hash` into `key="value"` pairs; pass the formatted string directly as the single value argument.

### Custom Schemes

Any other HTTP authentication scheme works the same way:

```ruby
# Authorization: ApiKey my-api-key
Faraday.new(...) do |conn|
  conn.request :authorization, 'ApiKey', 'my-api-key'
end
```

### With a proc or callable object

You can provide a proc (or any object responding to `#call`), which will be evaluated on each request:

```ruby
Faraday.new(...) do |conn|
  conn.request :authorization, 'Bearer', -> { MyAuthStorage.get_auth_token }
end
```

If the proc or `#call` method takes one argument, it will receive the forwarded `env` (see [The Env Object](getting-started/env-object.md)):

```ruby
Faraday.new(...) do |conn|
  conn.request :authorization, 'Bearer', ->(env) { MyAuthStorage.get_auth_token(env) }
end
```

```ruby
class TokenProvider
  def call(env)
    MyAuthStorage.get_auth_token(env)
  end
end

Faraday.new(...) do |conn|
  conn.request :authorization, 'Bearer', TokenProvider.new
end
```

### Faraday 1.x usage

In Faraday 1.x, `:basic_auth` and `:token_auth` were separate middleware, and `:token_auth` formatted the token and optional parameters into `key="value"` pairs:

```ruby
# Basic Auth request
# Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
Faraday.new(...) do |conn|
  conn.request :basic_auth, 'username', 'password'
end

# Token Auth request
# Formats the token and any options as comma-separated key="value" pairs
# Authorization: Token foo="bar", token="authentication-token"
Faraday.new(...) do |conn|
  conn.request :token_auth, 'authentication-token', foo: 'bar'
end

# Generic Auth Request
# Authorization: Bearer authentication-token
Faraday.new(...) do |conn|
  conn.request :authorization, 'Bearer', 'authentication-token'
end
```

When migrating from Faraday 1.x to 2.x:

- Replace `conn.request :basic_auth, 'username', 'password'` with `conn.request :authorization, :basic, 'username', 'password'`.
- Replace `conn.request :token_auth, 'authentication-token', foo: 'bar'` with `conn.request :authorization, 'Token', 'token="authentication-token", foo="bar"'` (or `'authentication-token'` if your API expects a bare token).
- Replace `conn.authorization`, `conn.basic_auth`, and `conn.token_auth` helper calls with `conn.request :authorization, ...`.
