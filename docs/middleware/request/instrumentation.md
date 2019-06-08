---
layout: documentation
title: "Instrumentation Middleware"
permalink: /middleware/instrumentation
hide: true
prev_name: Retry Middleware
prev_link: ./retry
next_name: Logger Middleware
next_link: ./logger
top_name: Back to Middleware
top_link: ./list
---

The `Instrumentation` middleware allows to instrument requests using different tools.
Options for this middleware include the instrumentation `name` and the `instrumenter` you want to use.
They default to `request.faraday` and `ActiveSupport::Notifications` respectively, but you can provide your own:

```ruby
conn = Faraday.new(...) do |f|
  f.request :instrumentation, name: 'custom_name', instrumenter: MyInstrumenter
  ...
end
```

### Example Usage

The `Instrumentation` middleware will use `ActiveSupport::Notifications` by default as instrumenter,
allowing you to subscribe to the default event name and instrument requests:

```ruby
conn = Faraday.new('http://example.com') do |f|
  f.request :instrumentation
  ...
end

ActiveSupport::Notifications.subscribe('request.faraday') do |name, starts, ends, _, env|
  url = env[:url]
  http_method = env[:method].to_s.upcase
  duration = ends - starts
  $stdout.puts '[%s] %s %s (%.3f s)' % [url.host, http_method, url.request_uri, duration]
end

conn.get('/search', { a: 1, b: 2 })
#=> [example.com] GET /search?a=1&b=2 (0.529 s)
```
