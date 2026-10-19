## Contributing

In Faraday we always welcome new ideas and features, however we also have to ensure
that the overall code quality stays on reasonable levels.
For this reason, before adding any contribution to Faraday, we highly recommend reading this
quick guide to ensure your PR can be reviewed and approved as quickly as possible.

We are past our 1.0 release, and follow [Semantic Versioning][semver]. If your
patch includes changes that break compatibility, note that in the Pull Request, so we can add it to
the [Changelog][].


### Policy on inclusive language

You have read our [Code of Conduct][], which includes a note about **inclusive language**. This section tries to make that actionable.

Faraday has a large and diverse userbase. To make Faraday a pleasant and effective experience for everyone, we use inclusive language.

These resources can help:

- Google's tutorial [Writing inclusive documentation](https://developers.google.com/style/inclusive-documentation) teaches by example, how to reword non-inclusive things.
- Linux kernel mailing list's [Coding Style: Inclusive Terminology](https://lkml.org/lkml/2020/7/4/229) said "Add no new instances of non-inclusive words, here is a list of words not include new ones of."
- Linguistic Society of America published [Guidelines for Inclusive Language](https://www.linguisticsociety.org/resource/guidelines-inclusive-language) which concluded: "We encourage all linguists to consider the possible reactions of their potential audience to their writing and, in so doing, to choose expository practices and content that is positive, inclusive, and respectful."

This project attempts to improve in these areas. Join us in doing that important work.

If you want to privately raise any breach to this policy with the Faraday team, feel free to reach out to [@iMacTia](https://ruby.social/@iMacTia) and [@olleolleolle](https://ruby.social/@olleolleolle) on the Mastodon instance ruby.social.


### Required Checks

Before pushing your code and opening a PR, we recommend you run the following checks to avoid
our GitHub Actions Workflow to block your contribution.

```bash
# Run unit tests and check code coverage
# (this excludes the integration tests, which need service containers)
$ bundle exec rake

# Check code style
$ bundle exec rubocop
```


### Integration Tests

The specs in `spec/integration/` exercise Faraday's options classes (`RequestOptions`, `SSLOptions`,
`ProxyOptions`, `ConnectionOptions` and `Env`) with real HTTP requests, so that refactorings of the
options can be checked for backward compatibility. They are not part of `bundle exec rake`, and run in
their own [GitHub Actions workflow](workflows/integration-tests.yml) on every pull request.

The workflow runs on the same Ruby versions as the main CI, each inside a `ruby` container next to a few service containers, which are reachable by name:

| Service      | URL                    | Used for                                         |
|--------------|------------------------|--------------------------------------------------|
| `httpbin`    | `http://httpbin`       | Echo, delay, status and streaming endpoints       |
| `proxy`      | `http://proxy:8080`    | Forward proxy (mitmproxy)                         |
| `auth-proxy` | `http://auth-proxy:8080` | Forward proxy requiring the `user` / `p@ss word` credentials |

A service container cannot be built from the repository, so what needs per-run configuration runs in
the rspec process instead: `spec/support/integration/` generates a throwaway CA and certificates in
memory (`TestPKI`) and serves HTTPS with them (`TLSServer`). Never commit certificates or keys.

The URLs can be overridden with the `HTTPBIN_URL`, `PROXY_URL` and `AUTH_PROXY_URL` environment variables.

#### Running them locally

The simplest way is `bin/integration-tests` (which needs Docker). It starts the same service containers as the
workflow on a private network, runs the specs in a `ruby` container next to them and cleans up afterwards.
It accepts rspec arguments, e.g. `bin/integration-tests spec/integration/options/env_integration_spec.rb`, and runs on Ruby 4.0 unless `RUBY_VERSION` is set (e.g. `RUBY_VERSION=3.0 bin/integration-tests`).

```bash
$ bin/integration-tests
```

[act](https://github.com/nektos/act) can't run the workflow because it doesn't support the `command` key of service containers.

The specs that only need httpbin (everything except `proxy_options_integration_spec.rb`) can also run
directly against a local httpbin:

```bash
$ docker run --rm -p 8099:80 kennethreitz/httpbin
$ HTTPBIN_URL=http://localhost:8099 COVERAGE=false bundle exec rspec spec/integration
```

`COVERAGE=false` keeps SimpleCov from enforcing the coverage thresholds, which make no sense for a subset of specs.

#### Adding integration tests

1. Add a `spec/integration/options/<name>_integration_spec.rb` file with `type: :integration`
   (files in `spec/integration/` are tagged automatically, which also disables WebMock for them).
2. Use the helpers from `spec/support/integration_helper.rb`, e.g. `httpbin_connection(options)`.
3. Test behavior through real requests and assert on what the server saw (httpbin echoes the request),
   not on Faraday internals. Each example must be independent of the others.
4. If a scenario needs a server that can't be an off-the-shelf service container, add a small helper
   under `spec/support/integration/` and start/stop it from the spec (see `ssl_options_integration_spec.rb`).
5. If you add or change a service container, update the readiness checks in the workflow as well.


### New Features

When adding a feature in Faraday:

1. also add tests to cover your new feature.
2. if the feature is for an adapter, the **attempt** must be made to add the same feature to all other adapters as well.
3. start opening an issue describing how the new feature will work, and only after receiving
the green light by the core team start working on the PR.


### New Middleware & Adapters

We prefer new adapters and middlewares to be added **as separate gems**. We can link to such gems from this project.

This goes for the [faraday_middleware][] project as well.

We encourage adapters that:

1. support SSL & streaming;
1. are proven and may have better performance than existing ones; or
1. have features not present in included adapters.


### Changes to the Faraday Docs

The Faraday Docs are included in the Faraday repository, under the `/docs` folder and deployed to [GitHub Pages][website].
If you want to apply changes to it, please test it locally before opening your PR.
You can find more information in the [Faraday Docs README][docs], including how to preview changes locally.


[semver]:               https://semver.org/
[changelog]:            https://github.com/lostisland/faraday/releases
[faraday_middleware]:   https://github.com/lostisland/faraday_middleware
[website]:              https://lostisland.github.io/faraday
[docs]:                 ../docs/README.md
[Code of Conduct]:      ./CODE_OF_CONDUCT.md
