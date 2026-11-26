# Authentication

The `Faraday::Request::Authorization` middleware allows you to automatically add an `Authorization` header
to your requests. It also features a handy helper to manage Basic authentication.
**Please note the way you use this middleware in Faraday 1.x is different**;
examples are available at the bottom of this page.

The middleware signature is:

```ruby
conn.request :authorization, type, *params
```

- `type` is not restricted to a fixed list of schemes. Any `String` or `Symbol` is accepted and interpolated
  verbatim as `Authorization: <type> <value>`, so casing is preserved: `'Token'` produces `Token ...`, while
  `:token` produces `token ...`.
- Basic authentication is the only scheme that takes two arguments (see [below](#basic-authentication)).
  Every other call expects a single `value`. Extra arguments raise `ArgumentError` when the first request is
  made, not when the connection is built.
- If a request already has an `Authorization` header (for example, set on an individual request), the
  middleware leaves it unchanged.

### Bearer Authentication

```ruby
# Authorization: Bearer authentication-token
Faraday.new(...) do |conn|
  conn.request :authorization, 'Bearer', 'authentication-token'
end
```

### Basic Authentication

When `type` is `:basic` or `'Basic'` (matched case-insensitively) and two arguments are provided, the
middleware Base64-encodes `username:password` for you:

```ruby
# Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
Faraday.new(...) do |conn|
  conn.request :authorization, :basic, 'username', 'password'
end
```

You can also pass a single pre-encoded credential string. As with any single value, `type` is used verbatim,
so use `'Basic'` here: `:basic` would produce `basic ...`.

```ruby
# Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
Faraday.new(...) do |conn|
  conn.request :authorization, 'Basic', 'dXNlcm5hbWU6cGFzc3dvcmQ='
end
```

### Token Authentication

Use `'Token'` for a capitalized scheme name, and format the value the way your API expects it:

```ruby
# Authorization: Token authentication-token
Faraday.new(...) do |conn|
  conn.request :authorization, 'Token', 'authentication-token'
end

# Authorization: Token token="authentication-token", scope="read"
Faraday.new(...) do |conn|
  conn.request :authorization, 'Token', 'token="authentication-token", scope="read"'
end
```

The value must be a string (or a callable returning one, see below). A `Hash` such as
`{ token: 'authentication-token' }` is **not** turned into `key="value"` pairs and raises no error: it is
interpolated as-is, producing an invalid header like `Token {token: "authentication-token"}`.

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

In Faraday 1.x, `:basic_auth` and `:token_auth` were separate middleware:

```ruby
# Basic Auth request
# Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
Faraday.new(...) do |conn|
  conn.request :basic_auth, 'username', 'password'
end

# Token Auth request
# The token and any options are formatted as comma-separated key="value" pairs, with token last
# Authorization: Token scope="read", token="authentication-token"
Faraday.new(...) do |conn|
  conn.request :token_auth, 'authentication-token', scope: 'read'
end

# Authorization request
# Authorization: Bearer authentication-token
Faraday.new(...) do |conn|
  conn.request :authorization, 'Bearer', 'authentication-token'
end
```

To support Faraday 1.x and 2.x with the same code, use `conn.request :authorization, type, value` with a
single string value, as in the last example above. This works in every 1.x release; a proc that takes no
arguments works from Faraday 1.8.0. Two-argument Basic, procs that take `env`, and other `#call` objects are
2.x only.

When migrating from Faraday 1.x to 2.x:

- Replace `conn.request :basic_auth, 'username', 'password'` with
  `conn.request :authorization, :basic, 'username', 'password'`.
- Replace `conn.request :token_auth, 'authentication-token'` with
  `conn.request :authorization, 'Token', 'token="authentication-token"'`. Options become extra pairs in the
  same string: `conn.request :token_auth, 'authentication-token', scope: 'read'` becomes
  `conn.request :authorization, 'Token', 'scope="read", token="authentication-token"'`.
  Faraday 1.x always sent the `token="..."` form, so only drop it for a bare token if your API accepts that.
- Replace `conn.authorization`, `conn.basic_auth`, and `conn.token_auth` helper calls with
  `conn.request :authorization, ...`.
