---
layout: documentation
title: "JSON Response Middleware"
permalink: /middleware/json-response
hide: true
prev_name: Instrumentation Middleware
prev_link: ./instrumentation
next_name: Logger Middleware
next_link: ./logger
top_name: Back to Middleware
top_link: ./list
---

The `JSON` response middleware parses response body into a hash of key/value pairs.
The behaviour can be customized with the following options:
* **parser_options:** options that will be sent to the JSON.parse method. Defaults to {}.
* **content_type:** Single value or Array of response content-types that should be processed. Can be either strings or Regex. Defaults to `/\bjson$/`.
* **preserve_raw:** If set to true, the original un-parsed response will be stored in the `response.env[:raw_body]` property. Defaults to `false`.

### Example Usage

```ruby
conn = Faraday.new('http://httpbingo.org') do |f|
  f.response :json, **options
end

conn.get('json').body
# => {"slideshow"=>{"author"=>"Yours Truly", "date"=>"date of publication", "slides"=>[{"title"=>"Wake up to WonderWidgets!", "type"=>"all"}, {"items"=>["Why <em>WonderWidgets</em> are great", "Who <em>buys</em> WonderWidgets"], "title"=>"Overview", "type"=>"all"}], "title"=>"Sample Slide Show"}}
```
