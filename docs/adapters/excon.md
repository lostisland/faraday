---
layout: documentation
title: "Excon Adapter"
permalink: /adapters/excon
hide: true
prev_name: Net::HTTP::Persistent Adapter
prev_link: ./net-http-persistent
top_name: Back to Adapters
top_link: ./
next_name: Patron Adapter
next_link: ./patron
---

This Adapter uses the [excon][rdoc] gem to make HTTP requests.

```ruby
conn = Faraday.new(...) do |f|
  # no custom options available
  f.adapter :excon
end
```

## Links

* [Gem RDoc][rdoc]
* [Gem source][src]
* [Adapter RDoc][adapter_rdoc]

[rdoc]: https://www.rubydoc.info/gems/excon
[src]: https://github.com/excon/excon
[adapter_rdoc]: https://www.rubydoc.info/gems/faraday/Faraday/Adapter/Excon
