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
## Fantastic adapters and where to find them

With the only exception being the [Test Adapter][testing], which is for _test purposes only_,
adapters are distributed separately from Faraday.
They are usually available as gems, or bundled with HTTP clients.

While most adapters use a common Ruby HTTP client library, adapters can also
have completely custom implementations.

If you're just getting started you can find a list of featured adapters in [Awesome Faraday][awesome].
Anyone can create a Faraday adapter and distribute it. If you're interested learning more, check how to [build your own][build_adapters]!

## Ad-hoc adapters customization

Faraday is intended to be a generic interface between your code and the adapter.
However, sometimes you need to access a feature specific to one of the adapters that is not covered in Faraday's interface.
When that happens, you can pass a block when specifying the adapter to customize it.
The block parameter will change based on the adapter you're using. See each adapter page for more details.

[testing]:        ./testing
[awesome]:        https://github.com/lostisland/awesome-faraday/#adapters
[build_adapters]: ./write_your_adapter.md
