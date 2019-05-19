---
# You don't need to edit this file, it's empty on purpose.
# Edit theme's home layout instead if you wanna make some changes
# See: https://jekyllrb.com/docs/themes/#overriding-theme-defaults
layout: page
title: Faraday
subtitle: Simple, but flexible HTTP client library, with support for multiple backends.
feature-img: "assets/img/home-banner.jpg"
hide: true
---

Faraday is an HTTP client library that provides a common interface over many adapters (such as Net::HTTP)
and embraces the concept of Rack middleware when processing the request/response cycle.

{: .text-center}
[<i class="fab fa-fw fa-github"> </i> Fork on GitHub](https://github.com/lostisland/faraday){: .btn}
[<i class="fab fa-fw fa-gitter"> </i> Chat with us](https://gitter.im/lostisland/faraday){: .btn}

{: .mt-60}
## Getting Started

Add this line to your application's Gemfile:

```ruby
gem 'faraday'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install faraday
```

You can also install the [`faraday_middleware`](https://github.com/lostisland/faraday_middleware)
extension gem to access a collection of useful Faraday middleware.

{: .mt-60}
## Usage

Table of contents:

* [Faraday API RubyDoc](http://www.rubydoc.info/gems/faraday)
* [Adapters](./adapters)
* [Middleware](./middleware)
  * [Middleware Environment](./middleware/env)
* [Testing](./testing)
