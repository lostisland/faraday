---
layout: documentation
title: "Write your own adapter"
permalink: /adapters/write_your_adapter
hide: true
order: 2
---

Adapters have methods that can help you implement support for a new backend.

This example will use a fictional HTTP backend gem called `FlorpHttp`. It doesn't
exist. Its only function is to make this example more concrete.

### An Adapter _is_ a Middleware

When you subclass `::Faraday::Adapter`, you get helpful methods defined:

```ruby
class FlorpHttp < ::Faraday::Adapter
end
```

Now, there are only two things which are actually mandatory for an adapter middleware to function:

- a `#call` implementation
- a call to `#save_response` inside `#call`, which will keep the Response around.

These are the only two things.
The rest of this text is about methods which make the authoring easier.

### Helpful method: `#build_connection`

Faraday abstracts all your backend's concrete stuff behind its user-facing API.
You take care of setting up the connection from the supplied parameters.

Example from the excon adapter: it gets an `Env` and reads its information
to instantiate an `Excon` object:

```ruby
class FlorpHttp < ::Faraday::Adapter
  def build_connection(env)
    opts = opts_from_env(env)
    ::Excon.new(env[:url].to_s, opts.merge(@connection_options))
  end
end
```

The `env` contains stuff like:

- `env[:ssl]`
- `env[:request]`

There are helper methods to fetch timeouts: `#request_timeout(type, options)` knows
about supported timeout types, and falls back to `:timeout` if they are not set.
You can use those when building the options you need for your backend's instantiation.

So, use the information provided in `env` to instantiate your backend's connection class.
Return that instance. Now, Faraday knows how to create and reuse that connection.

### Connection options and configuration block

Users of your adapter have two main ways of configuring it:
* connection options: these can be passed to your adapter initializer and are automatically stored into an instance variable `@connection_options`.
* configuration block: this can also be provided to your adapter initializer and it's stored into an instance variable `@config_block`.

Both of these are automatically managed by `Faraday::Adapter#initialize`, so remember to call it with `super` if you create an `initialize` method in your adapter.
You can then use them in your adapter code as you wish, since they're pretty flexible.

Below is an example of how they can be used:

```ruby
# You can use @connection_options and @config_block in your adapter code
class FlorpHttp < ::Faraday::Adapter
  def call(env)
    # `connection` internally calls `build_connection` and yields the result
    connection do |conn|
      # perform the request using configured `conn`
    end
  end

  def build_connection(env)
    conn = FlorpHttp::Client.new(pool_size: @connection_options[:pool_size] || 10)
    @config_block&.call(conn)
    conn
  end
end

# Then your users can provide them when initializing the connection
Faraday.new(...) do |f|
  # ...
  # in this example, { pool_size: 5 } will be provided as `connection_options`
  f.adapter :florp_http, pool_size: 5 do |client|
    # this block is useful to set properties unique to HTTP clients that are not
    # manageable through the Faraday API
    client.some_fancy_florp_http_property = 10
  end
end
```

### Nickname for your adapter: `.register_middleware`

You may register a nickname for your adapter. People can then refer to your adapter with that name.
You do that using `.register_middleware`, like this:

```ruby
class FlorpHttp < ::Faraday::Adapter
  # ...
end

Faraday::Adapter.register_middleware(florp_http: FlorpHttp)
```

## Does your backend support parallel operation?

:warning: This is slightly more involved, and this section is not fully formed.

Vague example, excerpted from [the test suite about parallel requests](https://github.com/lostisland/faraday/blob/master/spec/support/shared_examples/request_method.rb#L179)

```ruby
response_1 = nil
response_2 = nil

conn.in_parallel do
  response_1 = conn.get('/about')
  response_2 = conn.get('/products')
end

puts response_1.status
puts response_2.status
```

First, in your class definition, you can tell Faraday that your backend supports parallel operation:

```ruby
class FlorpHttp < ::Faraday::Adapter
  dependency do
    require 'florp_http'
  end

  self.supports_parallel = true
end
```

Then, implement a method which returns a ParallelManager:

```ruby
class FlorpHttp < ::Faraday::Adapter
  dependency do
    require 'florp_http'
  end

  self.supports_parallel = true

  def self.setup_parallel_manager(_options = nil)
    FlorpParallelManager.new # NB: we will need to define this
  end
end

class FlorpParallelManager
  def add(request, method, *args, &block)
    # Collect the requests
  end

  def run
    # Process the requests
  end
end
```

Compare to the finished example [em-synchrony](https://github.com/lostisland/faraday-em_synchrony/blob/main/lib/faraday/adapter/em_synchrony.rb)
and its [ParallelManager implementation](https://github.com/lostisland/faraday-em_synchrony/blob/main/lib/faraday/adapter/em_synchrony/parallel_manager.rb).
