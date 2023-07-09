# Test your custom adapter

Faraday puts a lot of expectations on adapters, but it also provides you with useful tools to test your adapter
against those expectations. This guide will walk you through the process of testing your adapter.

## The adapter test suite

Faraday provides a test suite that you can use to test your adapter.
The test suite is located in the `spec/external_adapters/faraday_specs_setup.rb`.

All you need to do is to `require 'faraday_specs_setup'` in your adapter's `spec_helper.rb` file.
This will load the `an adapter` shared example group that you can use to test your adapter.

```ruby
require 'faraday_specs_setup'

RSpec.describe Faraday::Adapter::FlorpHttp do
  it_behaves_like 'an adapter'

  # You can then add any other test specific to this adapter here...
end
```

## Testing optional features

By default, `an adapter` will test your adapter against the required behaviour for an adapter.
However, there are some optional "features" that your adapter can implement, like parallel requests or streaming.

If your adapter implements any of those optional features, you can test it against those extra expectations
by calling the `features` method:

```ruby
RSpec.describe Faraday::Adapter::MyAdapter do
  # Since not all adapters support all the features Faraday has to offer, you can use
  # the `features` method to turn on only the ones you know you can support.
  features :request_body_on_query_methods,
           :compression,
           :streaming

  # Runs the tests provide by Faraday, according to the features specified above.
  it_behaves_like 'an adapter'

  # You can then add any other test specific to this adapter here...
end
```

### Available features

* `:trace method`: tests your adapter against the `TRACE` HTTP method.
* `:local_socket_binding`: tests that your adapter supports binding to a local socket via the `:bind` request option.
* `:request_body_on_query_methods`: tests that your adapter supports sending a request body on `GET`, `HEAD`, `DELETE` and `TRACE` requests.
* `:reason_phrase_parse`: tests that your adapter supports parsing the reason_phrase from the response.
* `:compression`: tests that your adapter can handle `gzip` and `defalte` compressions.
* `:streaming`: tests that your adapter supports streaming responses. See [Streaming][streaming] for more details.
* `:parallel`: tests that your adapter supports parallel requests. See [Parallel requests][parallel] for more details.

[streaming]: /adapters/custom/streaming.md
[parallel]: /adapters/custom/parallel-requests.md
