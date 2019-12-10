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

## Ad-hoc adapters customization

Faraday is intended to be a generic interface between your code and the adapter.
However, sometimes you need to access a feature specific to one of the adapters that is not covered in Faraday's interface.
When that happens, you can pass a block when specifying the adapter to customize it.
The block parameter will change based on the adapter you're using. See each adapter page for more details.

[net_http]:     ./net-http
[persistent]:   ./net-http-persistent
[excon]:        ./excon
[patron]:       ./patron
[em-synchrony]: ./em-synchrony
[httpclient]:   ./httpclient
[typhoeus]:     https://github.com/typhoeus/typhoeus/blob/master/lib/typhoeus/adapters/faraday.rb
[faraday-http]: https://github.com/lostisland/faraday-http
[testing]:      ./testing
