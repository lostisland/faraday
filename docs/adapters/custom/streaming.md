# Adding support for streaming

Faraday supports streaming responses, which means that the response body is not loaded into memory all at once,
but instead it is read in chunks. This can be particularly useful when dealing with large responses.
Not all HTTP clients support this, so it is not required for adapters to support it.

However, if you do want to support it in your adapter, you can do so by leveraging helpers provided by the env object.
Let's see an example implementation first with some comments, and then we'll explain it in more detail:

```ruby
module Faraday
  class Adapter
    class FlorpHttp < Faraday::Adapter
      def call(env)
        super
        if env.stream_response? # check if the user wants to stream the response
          # start a streaming response.
          # on_data is a block that will let users consume the response body
          http_response = env.stream_response do |&on_data|
            # perform the request using FlorpHttp
            # the block will be called for each chunk of data
            FlorpHttp.perform_request(...) do |chunk|
              on_data.call(chunk)
            end
          end
          # the body is already consumed by the block
          # so it's good practice to set it to nil
          http_response.body = nil
        else
          # perform the request normally, no streaming.
          http_response = FlorpHttp.perform_request(...)
        end
        save_response(env, http_response.status, http_response.body, http_response.headers, http_response.reason_phrase)
      end
    end
  end
end
```

## How it works

### `#stream_response?`

The first helper method we use is `#stream_response?`. This method is provided by the env object and it returns true
if the user wants to stream the response. This is controlled by the presence of an `on_data` callback in the request options.

### `#stream_response`

The second helper is `#stream_response`. This method is also provided by the env object and it takes a block.
The block will be called with a single argument, which is a callback that the user can use to consume the response body.
All your adapter needs to do, is to call this callback with each chunk of data that you receive from the server.

The `on_data` callback will internally call the callback provided by the user, so you don't need to worry about that.
It will also keep track of the number of bytes that have been read, and pass that information to the user's callback.

To see how this all works together, let's see an example of how a user would use this feature:

```ruby
# A buffer to store the streamed data
streamed = []

conn = Faraday.new('http://httpbingo.org')
conn.get('/stream/100') do |req|
  # Set a callback which will receive tuples of chunk Strings,
  # the sum of characters received so far, and the response environment.
  # The latter will allow access to the response status, headers and reason, as well as the request info.
  req.options.on_data = proc do |chunk, overall_received_bytes, env|
    puts "Received #{overall_received_bytes} characters"
    streamed << chunk
  end
end

# Joins all response chunks together
streamed.join
```

For more details on the user experience, check the [Streaming Responses] page.

[Streaming Responses]: /advanced/streaming-responses.md
