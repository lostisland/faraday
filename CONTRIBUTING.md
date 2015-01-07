## Contributing

You can run the test suite against a live server by running `script/test`. It
automatically starts a test server in background. Only tests in
`test/adapters/*_test.rb` require a server, though.

``` sh
# run the whole suite
$ script/test

# run only specific files
$ script/test excon typhoeus

# run tests using SSL
$ SSL=yes script/test
```

We will accept middleware that:

1. is useful to a broader audience, but can be implemented relatively
   simple; and
2. which isn't already present in [faraday_middleware][] project.

We will accept adapters that:

1. support SSL & streaming;
1. are proven and may have better performance than existing ones; or
2. if they have features not present in included adapters.

We are pushing towards a 1.0 release, when we will have to follow [Semantic
Versioning][semver].  If your patch includes changes to break compatibility,
note that so we can add it to the [Changelog][].

[semver]:    http://semver.org/
[changelog]: https://github.com/lostisland/faraday/wiki/Changelog
[faraday_middleware]: https://github.com/lostisland/faraday_middleware/wiki
