---
layout: page
title: "Adapters"
permalink: /adapters
hide: true
---

Adapters are what performs the HTTP Request in the background.
They receive a `Faraday::Request` and make the actual call, returning a `Faraday::Response`.
Faraday allows you to change the adapter at any time through the configuration block.

{: .mt-60}
## Supported adapters

Faraday supports these adapters out of the box:

* [Net::HTTP][net_http] _(this is the default adapter)_
* [Net::HTTP::Persistent][persistent]
* [Excon][excon]
* [Patron][patron]
* [EM-Synchrony][em-synchrony]
* [HTTPClient][httpclient]

Adapters are slowly being moved into their own gems, or bundled with HTTP clients.
Please refer to their documentation for usage examples.
Here is the list of known external adapters:

* [Typhoeus][typhoeus]
* [HTTP.rb][faraday-http]

Faraday also includes a Rack adapter for hitting loaded Rack applications through
Rack::Test, and a [Test adapter][testing] for stubbing requests by hand.


[net_http]:     ./net-http
[persistent]:   ./net-http-persistent
[excon]:        ./excon
[patron]:       ./patron
[em-synchrony]: ./em-synchrony
[httpclient]:   ./httpclient
[typhoeus]:     https://github.com/typhoeus/typhoeus/blob/master/lib/typhoeus/adapters/faraday.rb
[faraday-http]: https://github.com/lostisland/faraday-http
[testing]:      ../testing