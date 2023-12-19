# JSON Encoding/Decoding

## JSON Requests

The `JSON` request middleware converts a `Faraday::Request#body` hash of key/value pairs into a JSON request body.
The middleware also automatically sets the `Content-Type` header to `application/json`,
processes only requests with matching Content-Type or those without a type and
doesn't try to encode bodies that already are in string form.

### Example Usage

```ruby
conn = Faraday.new(...) do |f|
  f.request :json
  ...
end

conn.post('/', { a: 1, b: 2 })
# POST with
# Content-Type: application/json
# Body: {"a":1,"b":2}
```

### Using custom JSON encoders

By default, middleware utilizes Ruby's `json` to generate JSON strings.

Other encoders can be used by specifying `encoder` option for the middleware:
* a module/class which implements `encode`
* a module/class-method pair to be used 

```ruby
require 'oj'

Faraday.new(...) do |f|
  f.request :json, encoder: Oj
end

Faraday.new(...) do |f|
  f.request :json, encoder: [Oj, :encode]
end
```

## JSON Responses

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
