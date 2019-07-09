---
layout: documentation
title: "Testing error cases"
permalink: /usage/testing-error-cases
hide: true
top_name: Usage
top_link: ./
prev_name: Streaming Responses
prev_link: ./streaming
---

When testing Faraday, green cases, or happy paths are quite easy to pick up and test.

```ruby
RSpec.describe SomeHttpService do
  let(:url) { "http://some-url-to.visit" }
  let(:connection) { class_double(Faraday) }

  before do
    allow(Faraday).to receive(:new).with(url: url).and_return(connection)
  end

  # checks for http status 2XX or similar
end
```

While it is important to test applications when everything is going well. It can be more helpful 
to test them when things are not so going so well. This is also a little more fun.

Given the ruby code


```ruby
class SomeHttpService
  class Error < StandardError; end

  def request(url, method)
    connection.public_send(method) do |req|
      req.url(url)
    end
  end
end
```

We could test for timeouts, which could be due to flaky network; slow response generation, etc.

```ruby
describe "#request" do
  let(:url) { "https://some.url" }
  context "When we encounter a timeout" do
    before(:each) do
      allow(connection).to receive(:public_send).and_raise(Faraday::TimeoutError.new(nil))
    end

    it "raises the expected error" do
      expect { described_class.new().request(url, data[:method]) }.to raise_error(
        Faraday::TimeoutError
      )
    end
  end
end
```
  
Of course in the real-world you may defer to your own response and error fallback classes. The point is to test 
for this happening.
  
  

We could test for connection errors, which could be due to incorrect URL's, unsupported protocols, etc

```ruby
describe "#request" do
  let(:url) { "badprotocol://some.url" }
  context "When we encounter a timeout" do
    before(:each) do
      allow(connection).to receive(:public_send).and_raise(Faraday::ConnectionFailed.new(nil))
    end

    it "blows up at some point" do
      expect { described_class.new().request(url, data[:method]) }.to raise_error(
        Faraday::ConnectionFailed
      )
    end
  end
end
```

Of course you will be free to get creative with the error classes.
