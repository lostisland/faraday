## Faraday 2.0

### Adapters have moved!

With this release, we've officially moved all adapters out of Faraday.
What that means, is that they won't be available out-of-the-box anymore,
and you'll instead need to add them to your Gemfile.

#### Why was this decision made?

We've taken this decision for the following technical reasons:

* We wanted the Faraday gem to focus on providing a clean, standardized, middleware-stack-based API.
* We wanted to free the core team from maintaining all the different adapters, relying more on the community to
  maintain them based on the broad interest. This will allow the core team to focus on implementing features
  focused on the Faraday API more quickly, without having to push it on all adapters immediately.
* With the community creating more and more adapters, we wanted to avoid having first and second-class adapters
  by having some of them included with the gem and others available externally.
* Moving adapters into separate gems allow to solve the dependency issues once and for all.
  Faraday will remain a dependency-free gem, while adapter gems will be able to automatically pull
  any necessary dependency, without having to rely on the developer to do so.

#### So what will this mean for me?

We did our best to make this transition as painless as possible for you, so here is what we did.

* All adapters have already been moved out and released as separate gems.
  They've then been re-added into Faraday's dependencies so that you wouldn't notice.
  This means that immediately after v2.0 will be released, all the adapters that were previously available will be
  already compatible with Faraday 2.0!
* We've setup an [Awesome Faraday](https://github.com/lostisland/awesome-faraday) repository, where you can find and discover adapters.
  We also highlighted their unique features and level of compliance with Faraday's features.

### Others

* Rename `Faraday::Request#method` to `#http_method`.

## Faraday 1.0

### Errors
* Removes sub-class constants definition from `Faraday::Error`. A sub-class (e.g. `ClientError`) was previously accessible
either through the `Faraday` module (e.g. `Faraday::ClientError`) or through the `Faraday::Error` class (e.g. `Faraday::Error::ClientError`).
The latter is no longer available and the former should be used instead, so check your `rescue`s.
* Introduces a new `Faraday::ServerError` (5xx status codes) alongside the existing `Faraday::ClientError` (4xx status codes).
Please note `Faraday::ClientError` was previously used for both.
* Introduces new Errors that describe the most common REST status codes:
  * Faraday::BadRequestError (400)
  * Faraday::UnauthorizedError (401)
  * Faraday::ForbiddenError (403)
  * Faraday::ProxyAuthError (407). Please note this raised a `Faraday::ConnectionFailed` before.
  * Faraday::ConflictError (409)
  * Faraday::UnprocessableEntityError (422)
* The following error classes have changed the hierarchy to better mirror their real-world usage and semantic meaning:
  * TimeoutError < ServerError (was < ClientError)
  * ConnectionFailed < Error (was < ClientError)
  * SSLError < Error (was < ClientError)
  * ParsingError < Error (was < ClientError)
  * RetriableResponse < Error (was < ClientError)

### Custom adapters
If you have written a custom adapter, please be aware that `env.body` is now an alias to the two new properties `request_body` and `response_body`.
This should work without you noticing if your adapter inherits from `Faraday::Adapter` and calls `save_response`, but if it doesn't, then please ensure you set the `status` BEFORE the `body` while processing the response.

### Others
* Dropped support for jruby and Rubinius.
* Officially supports Ruby 2.4+
* In order to specify the adapter you now MUST use the `#adapter` method on the connection builder. If you don't do so and your adapter inherits from `Faraday::Adapter` then Faraday will raise an exception. Otherwise, Faraday will automatically push the default adapter at the end of the stack causing your request to be executed twice.
```ruby
class OfficialAdapter < Faraday::Adapter
  ...
end

class MyAdapter
  ...
end

# This will raise an exception
conn = Faraday.new(...) do |f|
  f.use OfficialAdapter
end

# This will cause Faraday inserting the default adapter at the end of the stack
conn = Faraday.new(...) do |f|
  f.use MyAdapter
end

# You MUST use `adapter` method
conn = Faraday.new(...) do |f|
  f.adapter AnyAdapter
end
```
