---
layout: documentation
title: "EM-Synchrony Adapter"
permalink: /adapters/em-synchrony
hide: true
prev_name: Patron Adapter
prev_link: ./patron
top_name: Back to Adapters
top_link: ./
next_name: HTTPClient Adapter
next_link: ./httpclient
---

This Adapter uses the [em-synchrony][rdoc] gem to make HTTP requests.

```ruby
conn = Faraday.new(...) do |f|
  # no custom options available
  f.adapter :em_synchrony
end
```

## Links

* [Gem RDoc][rdoc]
* [Gem source][src]
* [Adapter RDoc][adapter_rdoc]
* [EM-HTTP Adapter](./em-http.md)

[rdoc]: https://www.rubydoc.info/gems/em-synchrony
[src]: https://github.com/igrigorik/em-synchrony
[adapter_rdoc]: https://www.rubydoc.info/gems/faraday/Faraday/Adapter/EMSynchrony
