# Request Options

Request options can be provided to the connection constructor or set on a per-request basis.
All these options are optional.

| Option            | Type              | Default                                                        | Description                                                             |
|-------------------|-------------------|----------------------------------------------------------------|-------------------------------------------------------------------------|
| `:params_encoder` | Class             | `Faraday::Utils.nested_params_encoder` (`NestedParamsEncoder`) | A custom class to use as the params encoder.                            |
| `:proxy`          | URI, String, Hash | nil                                                            | Proxy options, either as a URL or as a Hash of [ProxyOptions].          |
| `:bind`           | Hash              | nil                                                            | Hash of bind options. Requires the `:host` and `:port` keys.            |
| `:timeout`        | Integer, Float    | nil (adapter default)                                          | The max number of seconds to wait for the request to complete.          |
| `:open_timeout`   | Integer, Float    | nil (adapter default)                                          | The max number of seconds to wait for the connection to be established. |
| `:read_timeout`   | Integer, Float    | nil (adapter default)                                          | The max number of seconds to wait for one block to be read.             |
| `:write_timeout`  | Integer, Float    | nil (adapter default)                                          | The max number of seconds to wait for one block to be written.          |
| `:boundary`       | String            | nil                                                            | The boundary string for multipart requests.                             |
| `:context`        | Hash              | nil                                                            | Arbitrary data that you can pass to your request.                       |
| `:on_data`        | Proc              | nil                                                            | A callback that will be called when data is received. See [Streaming]   |

## Example

```ruby
# Request options can be passed to the connection constructor and will be applied to all requests.
request_options = {
  params_encoder: Faraday::FlatParamsEncoder,
  timeout: 5
}

conn = Faraday.new(request: request_options) do |faraday|
  # ...
end

# You can then override them on a per-request basis.
conn.get('/foo') do |req|
  req.options.timeout = 10
end
```

[ProxyOptions]: /customization/proxy-options.md
[SSLOptions]: /advanced/streaming-responses.md
