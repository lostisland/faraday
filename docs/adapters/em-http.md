---
layout: documentation
title: "EM-HTTP Adapter"
permalink: /adapters/em-http
hide: true
top_name: Adapters
top_link: ./
---

This Adapter uses [EventMachine](https://github.com/eventmachine/eventmachine/) and the tie in [em-http-request][src]

It can be used to make parallel requests using EventMachine.

The major difference between this and EMSynchrony is that it does not use fibers.

**Error handling and responses have a slightly different behaviour and structure in some cases.  Please run thorough testing scenarios, including connection failures and SSL failures**

You will need to add em-http-request to your Gemfile:

```ruby
# Gemfile
gem 'em-http-request'
```

### Base request
```ruby
require 'faraday'
require 'em-http-request'

conn = Faraday.new(...) do |f|
  # no custom options available
  f.adapter :em_http
end
```

### Parallel Requests

```ruby
require 'faraday'
require 'em-http-request'

urls = Array.new(5) { 'http://127.0.0.1:3000' }

conn = Faraday::Connection.new do |builder|
  builder.adapter :em_http
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
* [EM-Synchrony Adapter](./em-synchrony.md)

[rdoc]: https://www.rubydoc.info/gems/em-http-request
[src]: https://github.com/igrigorik/em-http-request#readme
[adapter_rdoc]: https://www.rubydoc.info/github/lostisland/faraday/Faraday/Adapter/EMHttp
