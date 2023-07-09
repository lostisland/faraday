# Net::HTTP Adapter

Faraday's Net::HTTP adapter is the default adapter. It uses the `Net::HTTP`
library that ships with Ruby's standard library.
Unless you have a specific reason to use a different adapter, this is probably
the adapter you want to use.

With the release of Faraday 2.0, the Net::HTTP adapter has been moved into a [separate gem][faraday-net_http],
but it has also been added as a dependency of Faraday.
That means you can use it without having to install it or require it explicitly.

[faraday-net_http]: https://github.com/lostisland/faraday-net_http
