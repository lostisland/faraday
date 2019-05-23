---
layout: page
title: "Streaming Responses"
permalink: /introduction/streaming
hide: true
---

Sometimes you might need to receive a streaming response.
You can easily do this with the `on_data` request option:

```ruby
## Streaming responses ##

streamed = []                       # A buffer to store the streamed data

conn.get('/nigiri/sake.json') do |req|
  # Set a callback which will receive tuples of chunk Strings
  # and the sum of characters received so far
  req.options.on_data = Proc.new do |chunk, overall_received_bytes|
    puts "Received #{overall_received_bytes} characters"
    streamed << chunk
  end
end

streamed.join                       # Joins all response chunks together 
```

At the moment, this is only supported by the `Net::HTTP` adapter, but support for other adapters
will be provided in future.
