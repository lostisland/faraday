# ![Faraday](_media/home-logo.svg)

Faraday is an HTTP client library abstraction layer that provides a common interface over many
adapters (such as Net::HTTP) and embraces the concept of Rack middleware when processing the request/response cycle.

## Why use Faraday?

Faraday gives you the power of Rack middleware for manipulating HTTP requests and responses,
making it easier to build sophisticated API clients or web service libraries that abstract away
the details of how HTTP requests are made.

Faraday comes with a lot of features out of the box, such as:
* Support for multiple adapters (Net::HTTP, Typhoeus, Patron, Excon, HTTPClient, and more)
* Persistent connections (keep-alive)
* Parallel requests
* Automatic response parsing (JSON, XML, YAML)
* Customization of the request/response cycle with middleware
* Support for streaming responses
* Support for uploading files
* And much more!

## Who uses Faraday?

Faraday is used by many popular Ruby libraries, such as:
* [Signet](https://github.com/googleapis/signet)
* [Octokit](https://github.com/octokit/octokit.rb)
* [Oauth2](https://bestgems.org/gems/oauth2)
* [Elasticsearch](https://github.com/elastic/elasticsearch-ruby)
