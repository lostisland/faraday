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

If you want to privately raise any breach to this policy with the Faraday team, feel free to reach out to [@iMacTia](https://twitter.com/iMacTia) and [@olleolleolle](https://twitter.com/olleolleolle) on Twitter.


### Required Checks

Before pushing your code and opening a PR, we recommend you run the following checks to avoid
our GitHub Actions Workflow to block your contribution.

```bash
# Run unit tests and check code coverage
$ bundle exec rspec

# Check code style
$ bundle exec rubocop
```


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
