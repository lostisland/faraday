---
layout: documentation
title: "Customizing the Request"
permalink: /usage/customize
hide: true
top_name: Usage
top_link: ./
next_name: Streaming Responses
next_link: ./streaming
---

Configuration can be set up with the connection and/or adjusted per request.

As connection options:

```ruby
conn = Faraday.new('http://sushi.com', request: { timeout: 5 })
conn.get('/search')
```

Or as per-request options:

```ruby
conn.get do |req|
  req.url '/search'
  req.options.timeout = 5
end
```

You can also inject arbitrary data into the request using the `context` option.
This will be available in the `env` on all middleware.

```ruby
conn.get do |req|
  req.url '/search'
  req.options.context = {
    foo: 'foo',
    bar: 'bar'
  }
end
```

## Changing how parameters are serialized

Sometimes you need to send the same URL parameter multiple times with different values.
This requires manually setting the parameter encoder and can be done on
either per-connection or per-request basis.
This applies to all HTTP verbs.

Per-connection setting:

```ruby
conn = Faraday.new request: { params_encoder: Faraday::FlatParamsEncoder }
conn.get('', { roll: ['california', 'philadelphia'] })
```

Per-request setting:

```ruby
conn.get do |req|
  req.options.params_encoder = Faraday::FlatParamsEncoder
  req.params = { roll: ['california', 'philadelphia'] }
end
```

### Custom serializers

You can build your custom encoder, if you like.

The value of Faraday `params_encoder` can be any object that responds to:

* `#encode(hash) #=> String`
* `#decode(string) #=> Hash`

The encoder will affect both how Faraday processes query strings and how it
serializes POST bodies.

The default encoder is `Faraday::NestedParamsEncoder`.

## Proxy

Faraday will try to automatically infer the proxy settings from your system using [`URI#find_proxy`][ruby-find-proxy].
This will retrieve them from environment variables such as http_proxy, ftp_proxy, no_proxy, etc.
If for any reason you want to disable this behaviour, you can do so by setting the global variable `ignore_env_proxy`:

```ruby
Faraday.ignore_env_proxy = true
```

You can also specify a custom proxy when initializing the connection:

```ruby
conn = Faraday.new('http://www.example.com', proxy: 'http://proxy.com')
```

[ruby-find-proxy]: https://ruby-doc.org/stdlib-2.6.3/libdoc/uri/rdoc/URI/Generic.html#method-i-find_proxy
