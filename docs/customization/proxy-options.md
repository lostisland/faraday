# Proxy Options

Proxy options can be provided to the connection constructor or set on a per-request basis via [RequestOptions](/customization/request-options.md).
All these options are optional.

| Option      | Type        | Default | Description     |
|-------------|-------------|---------|-----------------|
| `:uri`      | URI, String | nil     | Proxy URL.      |
| `:user`     | String      | nil     | Proxy user.     |
| `:password` | String      | nil     | Proxy password. |

## Example

```ruby
# Proxy options can be passed to the connection constructor and will be applied to all requests.
proxy_options = {
  uri: 'http://proxy.example.com:8080',
  user: 'username',
  password: 'password'
}

conn = Faraday.new(proxy: proxy_options) do |faraday|
  # ...
end

# You can then override them on a per-request basis.
conn.get('/foo') do |req|
  req.options.proxy.update(uri: 'http://proxy2.example.com:8080')
end
```
