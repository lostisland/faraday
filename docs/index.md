---
# You don't need to edit this file, it's empty on purpose.
# Edit theme's home layout instead if you wanna make some changes
# See: https://jekyllrb.com/docs/themes/#overriding-theme-defaults
layout: page
title: <img src="assets/img/home-logo.svg">
feature-img: "assets/img/featured-bg.svg"
hide: true
---

Faraday is an HTTP client library that provides a common interface over many adapters (such as Net::HTTP)
and embraces the concept of Rack middleware when processing the request/response cycle.

{: .text-center}
[<i class="fab fa-fw fa-github"> </i> Fork on GitHub][github]{: .btn}
[<i class="fab fa-fw fa-gitter"> </i> Chat with us][gitter]{: .btn}

{: .mt-60}
## Installation

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

You can also install the [`faraday_middleware`][faraday_middleware]
extension gem to access a collection of useful Faraday middleware.

{: .mt-60}

## SiteMap

* [Usage][usage]
  * [Customizing the Request][customize]
  * [Streaming Responses][streaming]
* [Middleware][middleware]
  * [Available Middleware][list]
  * [Writing Middleware][custom]
* [Adapters][adapters]
* [Testing][testing]
* [Team][team]
* [Faraday API RubyDoc](http://www.rubydoc.info/gems/faraday)

[github]:                   https://github.com/lostisland/faraday
[gitter]:                   https://gitter.im/lostisland/faraday
[faraday_middleware]:       https://github.com/lostisland/faraday_middleware
[usage]:                    ./usage
[customize]:                ./usage/customize
[streaming]:                ./usage/streaming
[middleware]:               ./middleware
[list]:                     ./middleware/list
[custom]:                   ./middleware/custom
[adapters]:                 ./adapters
[testing]:                  ./testing
[team]:                     ./team
