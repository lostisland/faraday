# Adding support for parallel requests

!> This is slightly more involved, and this section is not fully formed.

Vague example, excerpted from [the test suite about parallel requests](https://github.com/lostisland/faraday/blob/main/spec/support/shared_examples/request_method.rb#L179)

```ruby
response_1 = nil
response_2 = nil

conn.in_parallel do
  response_1 = conn.get('/about')
  response_2 = conn.get('/products')
end

puts response_1.status
puts response_2.status
```

First, in your class definition, you can tell Faraday that your backend supports parallel operation:

```ruby
class FlorpHttp < ::Faraday::Adapter
  dependency do
    require 'florp_http'
  end

  self.supports_parallel = true
end
```

Then, implement a method which returns a ParallelManager:

```ruby
class FlorpHttp < ::Faraday::Adapter
  dependency do
    require 'florp_http'
  end

  self.supports_parallel = true

  def self.setup_parallel_manager(_options = nil)
    FlorpParallelManager.new # NB: we will need to define this
  end

  def call(env)
    # NB: you can call `in_parallel?` here to check if the current request
    # is part of a parallel batch. Useful if you need to collect all requests
    # into the ParallelManager before running them.
  end
end

class FlorpParallelManager
  # The execute method will be passed the same block as `in_parallel`,
  # so you can either collect the requests or just wrap them into a wrapper,
  # depending on how your adapter works.
  def execute(&block)
    run_async(&block)
  end
end
```

### A note on the old, deprecated interface

Prior to the introduction of the `execute` method, the `ParallelManager` was expected to implement a `run` method
and the execution of the block was done by the Faraday connection BEFORE calling that method.

This approach made the `ParallelManager` implementation harder and forced you to keep state around.
The new `execute` implementation allows to avoid this shortfall and support different flows.

As of Faraday 2.0, `run` is still supported in case `execute` is not implemented by the `ParallelManager`,
but this method should be considered deprecated.

For reference, please see an example using `run` from [em-synchrony](https://github.com/lostisland/faraday-em_synchrony/blob/main/lib/faraday/adapter/em_synchrony.rb)
and its [ParallelManager implementation](https://github.com/lostisland/faraday-em_synchrony/blob/main/lib/faraday/adapter/em_synchrony/parallel_manager.rb).
