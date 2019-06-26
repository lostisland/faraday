---
layout: documentation
title: "EM-Synchrony Adapter"
permalink: /adapters/em-synchrony
hide: true
top_name: Adapters
top_link: ./
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
