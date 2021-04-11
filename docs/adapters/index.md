---
layout: documentation
title: "Adapters"
permalink: /adapters/
order: 2
---

The Faraday Adapter interface determines how a Faraday request is turned into
a Faraday response object. Adapters are typically implemented with common Ruby
HTTP clients, but can have custom implementations. Adapters can be configured
either globally or per Faraday Connection through the configuration block.

{: .mt-60}
## Built-in adapters

Faraday includes these adapters (but not the HTTP client libraries):

* [Net::HTTP][net_http] _(this is the default adapter)_
* [Net::HTTP::Persistent][persistent]
* [Excon][excon]
* [Patron][patron]
* [EM-Synchrony][em-synchrony]
* [EM-Http][em-http]
* [HTTPClient][httpclient]

While most adapters use a common Ruby HTTP client library, adapters can also
have completely custom implementations.

* [Test Adapter][testing]
* Rack Adapter (link TBD)

## External adapters

Adapters are slowly being moved into their own gems, or bundled with HTTP clients.
Please refer to their documentation for usage examples.

* [Typhoeus][typhoeus]
* [HTTP.rb][faraday-http]
* [httpx][httpx]

## Ad-hoc adapters customization

Faraday is intended to be a generic interface between your code and the adapter.
However, sometimes you need to access a feature specific to one of the adapters that is not covered in Faraday's interface.
When that happens, you can pass a block when specifying the adapter to customize it.
The block parameter will change based on the adapter you're using. See each adapter page for more details.

## Write your own adapter

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

There are helper to fetch timeouts: `#request_timeout(type, options)` knows
about supported timeout types, and falls back to `:timeout` if they are not set.
You can use those when building the options you need for your backend's instantiation.

So, use the information provided in `env` to instantiate your backend's connection class.
Return that instance. Now, Faraday knows how to create and reuse that connection.

### Nickname for your adapter: `.register_middleware`

You may register a nickname for your adapter. People can then refer to your adapter with that name.
You do that using `.register_middleware`, like this:

```ruby
class FlorpHttp < ::Faraday::Adapter
  register_middleware(
    File.expand_path('adapter', __dir__),
    florp_http: [ :FlorpHttp, 'florp_http' ]
  )
  # ...
end
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

Compare to the finished example [em-synchrony](https://github.com/lostisland/faraday/blob/master/lib/faraday/adapter/em_synchrony.rb) and its [ParallelManager implementation](https://github.com/lostisland/faraday/blob/master/lib/faraday/adapter/em_synchrony/parallel_manager.rb).

[net_http]:     ./net-http
[persistent]:   ./net-http-persistent
[excon]:        ./excon
[patron]:       ./patron
[em-synchrony]: ./em-synchrony
[em-http]:      ./em-http
[httpclient]:   ./httpclient
[typhoeus]:     https://github.com/typhoeus/typhoeus/blob/master/lib/typhoeus/adapters/faraday.rb
[faraday-http]: https://github.com/lostisland/faraday-http
[testing]:      ./testing
[httpx]:        https://honeyryderchuck.gitlab.io/httpx/wiki/Faraday-Adapter
