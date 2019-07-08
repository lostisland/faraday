---
layout: documentation
title: "Patron Adapter"
permalink: /adapters/patron
hide: true
top_name: Adapters
top_link: ./
---

This Adapter uses the [patron][rdoc] gem to make HTTP requests.

```ruby
conn = Faraday.new(...) do |f|
  f.adapter :patron do |session|
    # yields Patron::Session
    session.max_redirects = 10
  end
end
```

## Links

* [Gem RDoc][rdoc]
* [Gem source][src]
* [Adapter RDoc][adapter_rdoc]

[rdoc]: https://www.rubydoc.info/gems/patron
[src]: https://github.com/toland/patron
[adapter_rdoc]: https://www.rubydoc.info/gems/faraday/Faraday/Adapter/Patron
