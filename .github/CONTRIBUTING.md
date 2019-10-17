## Contributing

In Faraday we always welcome new ideas and features, however we also have to ensure
that the overall code quality stays on reasonable levels.
For this reason, before adding any contribution to Faraday, we highly recommend reading this
quick guide to ensure your PR can be reviewed and approved as quickly as possible.
 
We are pushing towards a 1.0 release, when we will have to follow [Semantic
Versioning][semver]. If your patch includes changes to break compatibility,
note that so we can add it to the [Changelog][].


### Required Checks

Before pushing your code and opening a PR, we recommend you run the following checks to avoid
our GitHub Actions Workflow to block your contribution.

```bash
# Run unit tests and check code coverage
$ bundle exec rspec

# Run Rubocop and check code style
$ bundle exec rubocop
```


### New Features

When adding a feature in Faraday:

1. also add tests to cover your new feature.
2. if the feature is for an adapter, the **attempt** must be made to add the same feature to all other adapters as well.
3. start opening an issue describing how the new feature will work, and only after receiving
the green light by the core team start working on the PR.


### New Middleware

We will accept middleware that:

1. is useful to a broader audience, but can be implemented relatively simple; and
2. which isn't already present in [faraday_middleware][] project.


### New Adapters

We will accept adapters that:

1. support SSL & streaming;
1. are proven and may have better performance than existing ones; or
2. if they have features not present in included adapters.


### Changes to Faraday Website

The [Faraday Website][website] is included in the Faraday repository, under the `/docs` folder.
If you want to apply changes to it, please test it locally using `Jekyll`.

```bash
# Navigate into the /docs folder
$ cd docs

# Install Jekyll dependencies, this bundle is different from Faraday's one.
$ bundle install

# Run the Jekyll server with the Faraday website
$ bundle exec jekyll serve

# The site will now be reachable at http://127.0.0.1:4000/faraday/
```

[semver]:               http://semver.org/
[changelog]:            https://github.com/lostisland/faraday/releases
[faraday_middleware]:   https://github.com/lostisland/faraday_middleware
[website]:              https://lostisland.github.io/faraday
