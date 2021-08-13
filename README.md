# [![Faraday](./docs/assets/img/repo-card-slim.png)][website]

[![Gem Version](https://badge.fury.io/rb/faraday.svg)](https://rubygems.org/gems/faraday)
[![GitHub Actions CI](https://github.com/lostisland/faraday/workflows/CI/badge.svg)](https://github.com/lostisland/faraday/actions?query=workflow%3ACI)
[![Gitter](https://badges.gitter.im/lostisland/faraday.svg)](https://gitter.im/lostisland/faraday?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)


Faraday is an HTTP client library that provides a common interface over many
adapters (such as Net::HTTP) and embraces the concept of Rack middleware when
processing the request/response cycle.

## ATTENTION

You're reading the README and looking at the code of our upcoming v2.0 release (the `main` branch).
If you're here to read about our latest v1.x release, then please head over to the [1.x branch](https://github.com/lostisland/faraday/tree/1.x).

## Getting Started

The best starting point is the [Faraday Website][website], with its introduction and explanation.
Need more details? See the [Faraday API Documentation][apidoc] to see how it works internally.

## Supported Ruby versions

This library aims to support and is [tested against][actions] the currently officially supported Ruby
implementations. This means that, even without a major release, we could add or drop support for Ruby versions,
following their [EOL](https://endoflife.date/ruby).
Currently that means we support Ruby 2.6+

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
But before you start coding, please read our [Contributing Guide][contributing]

## Copyright
&copy; 2009 - 2020, the [Faraday Team][faraday_team]. Website and branding design by [Elena Lo Piccolo](https://elelopic.design).

[website]:      https://lostisland.github.io/faraday
[faraday_team]: https://lostisland.github.io/faraday/team
[contributing]: https://github.com/lostisland/faraday/blob/master/.github/CONTRIBUTING.md
[apidoc]:       https://www.rubydoc.info/github/lostisland/faraday
[actions]:      https://github.com/lostisland/faraday/actions
[jruby]:        http://jruby.org/
[rubinius]:     http://rubini.us/
[license]:      LICENSE.md
