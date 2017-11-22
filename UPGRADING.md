## Faraday 1.0

* Dropped support for jruby and Rubinius.
* Officially supports Ruby 2.2+
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
