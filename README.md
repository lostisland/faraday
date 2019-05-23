# Faraday

[![Gem Version](https://badge.fury.io/rb/faraday.svg)](https://rubygems.org/gems/faraday)
[![CircleCI](https://circleci.com/gh/lostisland/faraday/tree/master.svg?style=svg)](https://circleci.com/gh/lostisland/faraday/tree/master)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f869daab091ceef1da73/test_coverage)](https://codeclimate.com/github/lostisland/faraday/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/f869daab091ceef1da73/maintainability)](https://codeclimate.com/github/lostisland/faraday/maintainability)
[![Gitter](https://badges.gitter.im/lostisland/faraday.svg)](https://gitter.im/lostisland/faraday?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)


Faraday is an HTTP client library that provides a common interface over many
adapters (such as Net::HTTP) and embraces the concept of Rack middleware when
processing the request/response cycle.

Faraday supports these adapters out of the box:

* [Net::HTTP][net_http] _(default)_
* [Net::HTTP::Persistent][persistent]
* [Excon][excon]
* [Patron][patron]
* [EM-Synchrony][em-synchrony]
* [HTTPClient][httpclient]

Adapters are slowly being moved into their own gems, or bundled with HTTP clients.
Here is the list of known external adapters:

* [Typhoeus][typhoeus]

It also includes a Rack adapter for hitting loaded Rack applications through
Rack::Test, and a Test adapter for stubbing requests by hand.

## Authentication

Basic and Token authentication are handled by Faraday::Request::BasicAuthentication and Faraday::Request::TokenAuthentication respectively.
These can be added as middleware manually or through the helper methods.

```ruby
Faraday.new(...) do |conn|
  conn.basic_auth('username', 'password')
end

Faraday.new(...) do |conn|
  conn.token_auth('authentication-token')
end
```

## Supported Ruby versions

This library aims to support and is [tested against][circle_ci] the following Ruby
implementations:

* Ruby 2.3+

If something doesn't work on one of these Ruby versions, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations and versions, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.

## Contribute

Do you want to contribute to Faraday?
Open the issues page and check for the `help wanted` label!
But before you start coding, please read our [Contributing Guide](https://github.com/lostisland/faraday/blob/master/.github/CONTRIBUTING.md)

## Copyright

Copyright (c) 2009-2019 [Rick Olson](mailto:technoweenie@gmail.com), Zack Hobson.
See [LICENSE][] for details.

[net_http]:     ./docs/adapters/net_http.md
[persistent]:   ./docs/adapters/net_http_persistent.md
[circle_ci]:       https://circleci.com/gh/lostisland/faraday
[excon]:        ./docs/adapters/excon.md
[patron]:       ./docs/adapters/patron.md
[em-synchrony]: ./docs/adapters/em-synchrony.md
[httpclient]:   ./docs/adapters/httpclient.md
[typhoeus]:     https://github.com/typhoeus/typhoeus/blob/master/lib/typhoeus/adapters/faraday.rb
[jruby]:        http://jruby.org/
[rubinius]:     http://rubini.us/
[license]:      LICENSE.md
