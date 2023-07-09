# Adapters

The Faraday Adapter interface determines how a Faraday request is turned into
a Faraday response object. Adapters are typically implemented with common Ruby
HTTP clients, but can have custom implementations. Adapters can be configured
either globally or per Faraday Connection through the configuration block.

For example, consider using `httpclient` as an adapter. Note that [faraday-httpclient](https://github.com/lostisland/faraday-httpclient) must be installed beforehand.

If you want to configure it globally, do the following:

```ruby
require 'faraday'
require 'faraday/httpclient'

Faraday.default_adapter = :httpclient
```

If you want to configure it per Faraday Connection, do the following:

```ruby
require 'faraday'
require 'faraday/httpclient'

conn = Faraday.new do |f|
  f.adapter :httpclient
end
```

## Fantastic adapters and where to find them

Except for the default [Net::HTTP][net_http] adapter and the [Test Adapter][testing] adapter, which is for _test purposes only_,
adapters are distributed separately from Faraday and need to be manually installed.
They are usually available as gems, or bundled with HTTP clients.

While most adapters use a common Ruby HTTP client library, adapters can also
have completely custom implementations.

If you're just getting started you can find a list of featured adapters in [Awesome Faraday][awesome].
Anyone can create a Faraday adapter and distribute it. If you're interested learning more, check how to [build your own][build_adapters]!


[testing]:        /adapters/test-adapter.md
[net_http]:       /adapters/net-http.md
[awesome]:        https://github.com/lostisland/awesome-faraday/#adapters
[build_adapters]: /adapters/custom/index.md
