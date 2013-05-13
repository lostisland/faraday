# Faraday Changelog

## v0.9.0

* Add HTTPClient adapter (@hakanensari)
* Improve Retry handler (@mislav)
* Remove autoloading by default (@technoweenie)
* Improve internal docs (@technoweenie, @mislav)
* Respect user/password in http proxy string (@mislav)
* Adapter options are structs.  Reinforces consistent options across adapters
  (@technoweenie)
* Stop stripping trailing / off base URLs in a Faraday::Connection. (@technoweenie)
* Add a configurable URI parser. (@technoweenie)
* Remove need to manually autoload when using the authorization header helpers on `Faraday::Connection`. (@technoweenie)
* `Faraday::Adapter::Test` respects the `Faraday::RequestOptions#params_encoder` option. (@technoweenie)
