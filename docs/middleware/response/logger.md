---
layout: documentation
title: "Logger Middleware"
permalink: /middleware/logger
hide: true
prev_name: Instrumentation Middleware
prev_link: ./instrumentation
next_name: RaiseError Middleware
next_link: ./raise-error
top_name: Back to Middleware
top_link: ./list
---

The `Logger` middleware logs both the request and the response body and headers.
It is highly customizable and allows to mask confidential information if necessary.

### Basic Usage

```ruby
conn = Faraday.new(url: 'http://sushi.com') do |faraday|
  faraday.response :logger # log requests and responses to $stdout
end

conn.get
# => INFO  -- request: GET http://sushi.com/
# => DEBUG -- request: User-Agent: "Faraday v1.0.0"
# => INFO  -- response: Status 301
# => DEBUG -- response: date: "Sun, 19 May 2019 16:05:40 GMT"
```

### Customize the logger

By default, the `Logger` middleware uses the Ruby `Logger.new($stdout)`.
You can customize it to use any logger you want by providing it when you add the middleware to the stack:

```ruby
conn = Faraday.new(url: 'http://sushi.com') do |faraday|
  faraday.response :logger, MyLogger.new($stdout)
end
```

### Include and exclude headers/bodies

By default, the `logger` middleware logs only headers for security reasons, however, you can configure it
to log bodies as well, or disable headers logging if you need to. To do so, simply provide a configuration hash
when you add the middleware to the stack:

```ruby
conn = Faraday.new(url: 'http://sushi.com') do |faraday|
  faraday.response :logger, nil, { headers: true, bodies: true }
end
```

Please note this only works with the default formatter.

### Filter sensitive information

You can filter sensitive information from Faraday logs using a regex matcher:

```ruby
conn = Faraday.new(url: 'http://sushi.com') do |faraday|
  faraday.response :logger do | logger |
    logger.filter(/(api_key=)(\w+)/, '\1[REMOVED]')
  end
end

conn.get('/', api_key: 'secret')
# => INFO  -- request: GET http://sushi.com/?api_key=[REMOVED]
# => DEBUG -- request: User-Agent: "Faraday v1.0.0"
# => INFO  -- response: Status 301
# => DEBUG -- response: date: "Sun, 19 May 2019 16:12:36 GMT"
```

### Change log level

By default, the `logger` middleware logs on the `info` log level. It is possible to configure
the severity by providing the `log_level` option:

```ruby
conn = Faraday.new(url: 'http://sushi.com') do |faraday|
  faraday.response :logger, nil, { bodies: true, log_level: :debug }
end
```

### Customize the formatter

You can also provide a custom formatter to control how requests and responses are logged.
Any custom formatter MUST implement the `request` and `response` method, with one argument which
will be passed being the Faraday environment. 
If you make your formatter inheriting from `Faraday::Response::Logger::Formatter`,
then the methods `debug`, `info`, `warn`, `error` and `fatal` are automatically delegated to the logger.

```ruby
class MyFormatter < Faraday::Logging::Formatter
  def request(env)
    # Build a custom message using `env`
    info('Request') { 'Sending Request' }
  end

  def response(env)
    # Build a custom message using `env` 
    info('Response') { 'Response Received' }
  end
end

conn = Faraday.new(url: 'http://sushi.com/api_key=s3cr3t') do |faraday|
  faraday.response :logger, nil, formatter: MyFormatter
end
```