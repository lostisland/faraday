# Net::HTTP Adapter

Faraday's Net::HTTP adapter is the default adapter. It uses the `Net::HTTP`
library that ships with Ruby's standard library.
Unless you have a specific reason to use a different adapter, this is probably
the adapter you want to use.

With the release of Faraday 2.0, the Net::HTTP adapter has been moved into a [separate gem][faraday-net_http],
but it has also been added as a dependency of Faraday.
That means you can use it without having to install it or require it explicitly.

## Supported Options

Faraday options are common to all adapters, but each adapter decides which of them it supports.
This section lists the ones the Net::HTTP adapter supports. Any other option is ignored.

### SSL Options

[SSL Options][ssl_options] are only applied to `https` URLs.

| Option             | Net::HTTP setting             | Notes                                                                                                              |
|--------------------|-------------------------------|--------------------------------------------------------------------------------------------------------------------|
| `:verify`          | `verify_mode`                 | `OpenSSL::SSL::VERIFY_PEER` unless `false`, in which case it's `OpenSSL::SSL::VERIFY_NONE`.                        |
| `:verify_mode`     | `verify_mode`                 | Takes precedence over `:verify`.                                                                                   |
| `:verify_hostname` | `verify_hostname`             |                                                                                                                    |
| `:ca_file`         | `ca_file`                     |                                                                                                                    |
| `:ca_path`         | `ca_path`                     |                                                                                                                    |
| `:cert_store`      | `cert_store`                  | Defaults to a store using the system's default CA certificates.                                                    |
| `:client_cert`     | `cert` and `extra_chain_cert` | Either a certificate or an Array of certificates. The first one is the client certificate, the rest are its chain. |
| `:client_key`      | `key`                         |                                                                                                                    |
| `:verify_depth`    | `verify_depth`                |                                                                                                                    |
| `:version`         | `ssl_version`                 |                                                                                                                    |
| `:min_version`     | `min_version`                 |                                                                                                                    |
| `:max_version`     | `max_version`                 |                                                                                                                    |
| `:ciphers`         | `ciphers`                     |                                                                                                                    |

`:hostname`, `:certificate` and `:private_key` are not supported.

```ruby
ssl_options = {
  client_cert: OpenSSL::X509::Certificate.new(File.read('/path/to/client.crt')),
  client_key: OpenSSL::PKey.read(File.read('/path/to/client.key')),
  ca_file: '/path/to/ca.pem',
  min_version: :TLS1_2
}

conn = Faraday.new(url: 'https://example.com', ssl: ssl_options)
```

### Request Options

| Option           | Net::HTTP setting | Notes                                                                      |
|------------------|-------------------|----------------------------------------------------------------------------|
| `:timeout`       |                   | Used for `:open_timeout`, `:read_timeout` and `:write_timeout` if not set. |
| `:open_timeout`  | `open_timeout`    |                                                                            |
| `:read_timeout`  | `read_timeout`    |                                                                            |
| `:write_timeout` | `write_timeout`   |                                                                            |
| `:proxy`         | proxy arguments   | See [Proxy Options][proxy_options]. `https` proxies are supported.         |
| `:on_data`       |                   | See [Streaming Responses][streaming].                                      |

`:bind` is not supported.
The adapter also sets `max_retries` to `0`, so Net::HTTP never retries a request on its own.
Use the [faraday-retry][faraday-retry] middleware if you want retries.

### Configuring Net::HTTP directly

For anything not covered above, pass a block to `adapter`.
It's called with the `Net::HTTP` instance before every request, after Faraday's own options have been applied,
so it can also override them.

```ruby
conn = Faraday.new(url: 'https://example.com') do |f|
  f.adapter :net_http do |http|
    http.set_debug_output($stderr)
  end
end
```

[faraday-net_http]: https://github.com/lostisland/faraday-net_http
[faraday-retry]:    https://github.com/lostisland/faraday-retry
[ssl_options]:      /customization/ssl-options.md
[proxy_options]:    /customization/proxy-options.md
[streaming]:        /advanced/streaming-responses.md
