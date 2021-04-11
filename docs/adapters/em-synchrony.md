---
layout: documentation
title: "EM-Synchrony Adapter"
permalink: /adapters/em-synchrony
hide: true
top_name: Adapters
top_link: ./
---

This Adapter uses [EventMachine](https://github.com/eventmachine/eventmachine/) and the tie in [em-http-request](https://www.rubydoc.info/gems/em-http-request) in conjunction with [em-synchrony][rdoc]

It can be used to make parallel requests using EventMachine.

The key difference between this and EM-Http is that it uses fibers.  For more information see igrigorik's blog posts on the matter:

- [fibers-cooperative-scheduling-in-ruby](https://www.igvita.com/2009/05/13/fibers-cooperative-scheduling-in-ruby/)
- [untangling-evented-code-with-ruby-fibers](https://www.igvita.com/2010/03/22/untangling-evented-code-with-ruby-fibers)

**Error handling and responses have a slightly different behaviour and structure in some cases.  Please run thorough testing scenarios, including connection failures and SSL failures**

You will need to add em-http-request and em-synchrony to your Gemfile:

```ruby
# Gemfile
gem 'em-http-request'
gem 'em-synchrony'
```

### Base request
```ruby
require 'faraday'
require 'em-http-request'
require 'em-synchrony'

conn = Faraday.new(...) do |f|
  # no custom options available
  f.adapter :em_synchrony
end
```

### Parallel Requests

```ruby
require 'faraday'
require 'em-http-request'
require 'em-synchrony'

urls = Array.new(5) { 'http://127.0.0.1:3000' }

conn = Faraday::Connection.new do |builder|
  builder.adapter :em_synchrony
end

begin
  conn.in_parallel do
    puts "Parallel manager: #{conn.parallel_manager}"

    @responses = urls.map do |url|
      conn.get(url)
    end
  end
end

# Gather responses outside of block
puts @responses.map(&:status).join(', ')
puts @responses.map(&:status).compact.count
```

## Links

* [Gem RDoc][rdoc]
* [Gem source][src]
* [Adapter RDoc][adapter_rdoc]
* [EM-HTTP Adapter](./em-http.md)

[rdoc]: https://www.rubydoc.info/gems/em-synchrony
[src]: https://github.com/igrigorik/em-synchrony
[adapter_rdoc]: https://www.rubydoc.info/github/lostisland/faraday/Faraday/Adapter/EMSynchrony
