# Connection Options

When initializing a new Faraday connection with `Faraday.new`, you can pass a hash of options to customize the connection.
All these options are optional.

| Option              | Type              | Default         | Description                                                                                                   |
|---------------------|-------------------|-----------------|---------------------------------------------------------------------------------------------------------------|
| `:request`          | Hash              | nil             | Hash of request options. Will be use to build [RequestOptions].                                               |
| `:proxy`            | URI, String, Hash | nil             | Proxy options, either as a URL or as a Hash of [ProxyOptions].                                                |
| `:ssl`              | Hash              | nil             | Hash of SSL options. Will be use to build [SSLOptions].                                                       |
| `:url`              | URI, String       | nil             | URI or String base URL. This can also be passed as positional argument.                                       |
| `:parallel_manager` |                   | nil             | Default parallel manager to use. This is normally set by the adapter, but you have the option to override it. |
| `:params`           | Hash              | nil             | URI query unencoded key/value pairs.                                                                          |
| `:headers`          | Hash              | nil             | Hash of unencoded HTTP header key/value pairs.                                                                |
| `:builder_class`    | Class             | RackBuilder     | A custom class to use as the middleware stack builder.                                                        |
| `:builder`          | Object            | Rackbuilder.new | An instance of a custom class to use as the middleware stack builder.                                         |

## Example

```ruby
options = {
  request: {
    open_timeout: 5,
    timeout: 5
  },
  proxy: {
    uri: 'https://proxy.com',
    user: 'proxy_user',
    password: 'proxy_password'
  },
  ssl: {
    ca_file: '/path/to/ca_file',
    ca_path: '/path/to/ca_path',
    verify: true
  },
  url: 'https://example.com',
  params: { foo: 'bar' },
  headers: { 'X-Api-Key' => 'secret', 'X-Api-Version' => '2' }
}

conn = Faraday.new(options) do |faraday|
  # ...
end
```

[RequestOptions]: /customization/request-options.md
[ProxyOptions]: /customization/proxy-options.md
[SSLOptions]: /customization/ssl-options.md
