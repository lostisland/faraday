---
layout: documentation
title: "HTTPClient Adapter"
permalink: /adapters/httpclient
hide: true
top_name: Adapters
top_link: ./
---

This Adapter uses the [httpclient][rdoc] gem to make HTTP requests.

```ruby
conn = Faraday.new(...) do |f|
  f.adapter :httpclient do |client|
    # yields HTTPClient
    client.keep_alive_timeout = 20
    client.ssl_config.timeout = 25
  end
end
```

## Links

* [Gem RDoc][rdoc]
* [Gem source][src]
* [Adapter RDoc][adapter_rdoc]

[rdoc]: https://www.rubydoc.info/gems/httpclient
[src]: https://github.com/nahi/httpclient
[adapter_rdoc]: https://www.rubydoc.info/gems/faraday/Faraday/Adapter/HTTPClient
