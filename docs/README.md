# Faraday Website

This is the root directory of the [Faraday Website][website].
If you want to apply changes to it, please test it locally using `Jekyll`.

Here is how:

```bash
# Navigate into the /docs folder
$ cd docs

# Install Jekyll dependencies, this bundle is different from Faraday's one.
$ bundle install

# Run the Jekyll server with the Faraday website
$ bundle exec jekyll serve

# The site will now be reachable at http://127.0.0.1:4000/faraday/
```

On newer Ruby versions (>= 3.0) `eventmachine` needs a little help to find OpenSSL 1.1 to get compiled (see <https://github.com/eventmachine/eventmachine/issues/936>). If you're using homebrew on macOS, you can do this:

```bash
brew install openssl@1.1
bundle config build.eventmachine --with-openssl-dir=$(brew --prefix openssl@1.1)
bundle install
```

[website]: https://lostisland.github.io/faraday
