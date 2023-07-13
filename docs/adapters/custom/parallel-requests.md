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
end

class FlorpParallelManager
  def add(request, method, *args, &block)
    # Collect the requests
  end

  def run
    # Process the requests
  end
end
```

Compare to the finished example [em-synchrony](https://github.com/lostisland/faraday-em_synchrony/blob/main/lib/faraday/adapter/em_synchrony.rb)
and its [ParallelManager implementation](https://github.com/lostisland/faraday-em_synchrony/blob/main/lib/faraday/adapter/em_synchrony/parallel_manager.rb).
