---
layout: documentation
title: "Net::HTTP Adapter"
permalink: /adapters/net-http
hide: true
top_name: Adapters
top_link: ./
---

This Adapter uses the [`Net::HTTP`][rdoc] client from the Ruby standard library to make
HTTP requests.

```ruby
conn = Faraday.new(...) do |f|
  f.adapter :net_http do |http|
    # yields Net::HTTP
    http.idle_timeout = 100
    http.verify_callback = lambda do |preverify, cert_store|
      # do something here...
    end
  end
end
```

## Links

* [Net::HTTP RDoc][rdoc]
* [Adapter RDoc][adapter_rdoc]

[rdoc]: http://ruby-doc.org/stdlib/libdoc/net/http/rdoc/Net/HTTP.html
[adapter_rdoc]: https://www.rubydoc.info/gems/faraday/Faraday/Adapter/NetHttp
