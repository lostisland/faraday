# Net::HTTP::Persistent

This Adapter uses the [net-http-persistent][gem] gem to make HTTP requests.

```ruby
conn = Faraday.new(...) do |f|
  f.adapter :net_http_persistent, pool_size: 5 do |http|
    # yields Net::HTTP::Persistent
    http.idle_timeout = 100
    http.retry_change_requests = true
  end
end
```

## Links

* [Gem][gem]
* [Gem source code][src]
* [Adapter rdoc][rdoc]

[gem]: https://rubygems.org/gems/net-http-persistent/versions/2.9.4
[src]: https://github.com/drbrain/net-http-persistent
[rdoc]: https://www.rubydoc.info/gems/faraday/Faraday/Adapter/NetHttpPersistent
