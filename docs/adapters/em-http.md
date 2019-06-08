---
layout: documentation
title: "EM-HTTP Adapter"
permalink: /adapters/em-http
hide: true
prev_name: Patron Adapter
prev_link: ./patron
top_name: Back to Adapters
top_link: ./
next_name: HTTPClient Adapter
next_link: ./httpclient
---

This Adapter uses the [em-http-request][rdoc] gem to make HTTP requests.

```ruby
conn = Faraday.new(...) do |f|
  # no custom options available
  f.adapter :em_http
end
```

## Links

* [Gem RDoc][rdoc]
* [Gem source][src]
* [Adapter RDoc][adapter_rdoc]

[rdoc]: https://www.rubydoc.info/gems/em-http-request
[src]: https://github.com/igrigorik/em-http-request#readme
[adapter_rdoc]: https://www.rubydoc.info/gems/faraday/Faraday/Adapter/EMHttp
