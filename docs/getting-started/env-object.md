# The Env Object

Inspired by Rack, Faraday uses an `env` object to pass data between middleware.
This object is initialized at the beginning of the request and passed down the middleware stack.
The adapter is then responsible to run the HTTP request and set the `response` property on the `env` object,
which is then passed back up the middleware stack.

You can read more about how the `env` object is used in the [Middleware - How it works](/middleware/index?id=how-it-works) section.

Because of its nature, the `env` object is a complex structure that holds a lot of information and can
therefore be a bit intimidating at first. This page will try to explain the different properties of the `env` object.

## Properties

Please also note that these properties are not all available at the same time: while configuration
and request properties are available at the beginning of the request, response properties are only
available after the request has been performed (i.e. in the `on_complete` callback of middleware).


| Property            | Type                       |      Request       |      Response      | Description                 |
|---------------------|----------------------------|:------------------:|:------------------:|-----------------------------|
| `:method`           | `Symbol`                   | :heavy_check_mark: | :heavy_check_mark: | The HTTP method to use.     |
| `:request_body`     | `String`                   | :heavy_check_mark: | :heavy_check_mark: | The request body.           |
| `:url`              | `URI`                      | :heavy_check_mark: | :heavy_check_mark: | The request URL.            |
| `:request`          | `Faraday::RequestOptions`  | :heavy_check_mark: | :heavy_check_mark: | The request options.        |
| `:request_headers`  | `Faraday::Utils::Headers`  | :heavy_check_mark: | :heavy_check_mark: | The request headers.        |
| `:ssl`              | `Faraday::SSLOptions`      | :heavy_check_mark: | :heavy_check_mark: | The SSL options.            |
| `:parallel_manager` | `Faraday::ParallelManager` | :heavy_check_mark: | :heavy_check_mark: | The parallel manager.       |
| `:params`           | `Hash`                     | :heavy_check_mark: | :heavy_check_mark: | The request params.         |
| `:response`         | `Faraday::Response`        |        :x:         | :heavy_check_mark: | The response.               |
| `:response_headers` | `Faraday::Utils::Headers`  |        :x:         | :heavy_check_mark: | The response headers.       |
| `:status`           | `Integer`                  |        :x:         | :heavy_check_mark: | The response status code.   |
| `:reason_phrase`    | `String`                   |        :x:         | :heavy_check_mark: | The response reason phrase. |
| `:response_body`    | `String`                   |        :x:         | :heavy_check_mark: | The response body.          |

## Helpers

The `env` object also provides some helper methods to make it easier to work with the properties.

| Method                  | Description                                                                                      |
|-------------------------|--------------------------------------------------------------------------------------------------|
| `#body`/`#current_body` | Returns the request or response body, based on the presence of `#status`.                        |
| `#success?`             | Returns `true` if the response status is in the 2xx range.                                       |
| `#needs_body?`          | Returns `true` if there's no body yet, and the method is in the set of `Env::MethodsWithBodies`. |
| `#clear_body`           | Clears the body, if it's present. That includes resetting the `Content-Length` header.           |
| `#parse_body?`          | Returns `true` unless the status indicates otherwise (e.g. 204, 304).                            |
| `#parallel?`            | Returns `true` if a parallel manager is available.                                               |
| `#stream_response?`     | Returns `true` if the `on_data` streaming callback has been provided.                            |
| `#stream_response`      | Helper method to implement streaming in adapters. See [Support streaming in your adapter]        |

[Support streaming in your adapter]: /adapters/custom/streaming.md
