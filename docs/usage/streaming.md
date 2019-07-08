---
layout: documentation
title: "Streaming Responses"
permalink: /usage/streaming
hide: true
top_name: Usage
top_link: ./
prev_name: Customizing the Request
prev_link: ./customize
---

Sometimes you might need to receive a streaming response.
You can do this with the `on_data` request option.

The `on_data` callback is a receives tuples of chunk Strings, and the total
of received bytes so far.

This example implements such a callback:

```ruby
# A buffer to store the streamed data
streamed = []

conn.get('/nigiri/sake.json') do |req|
  # Set a callback which will receive tuples of chunk Strings
  # and the sum of characters received so far
  req.options.on_data = Proc.new do |chunk, overall_received_bytes|
    puts "Received #{overall_received_bytes} characters"
    streamed << chunk
  end
end

# Joins all response chunks together
streamed.join
```

The `on_data` streaming is currently only supported by the `Net::HTTP` adapter.
